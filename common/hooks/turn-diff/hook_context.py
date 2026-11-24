import json
import sys
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

from git_snapshot import git_cache_dir, git_worktree_root

AgentKind = Literal["codex", "antigravity"]
ACTIVE_TURN_FILE = "active-turn"
STATUS_FILE = "status.txt"


@dataclass(frozen=True)
class HookContext:
    """
    Resolved repository, session, and turn metadata for a CLI hook invocation.

    Attributes:
        agent (AgentKind): Agent that emitted the hook payload.
        root (Path): Git worktree root.
        session_dir (Path): Cache directory for the current session.
        turn_id (str | None): Explicit turn ID when provided by the agent.
        invocation_num (int | None): Zero-based invocation index for Antigravity
            `PreInvocation` hooks, or None otherwise.
    """

    agent: AgentKind
    root: Path
    session_dir: Path
    turn_id: str | None = None
    invocation_num: int | None = None


def detect_agent(payload: dict[str, Any]) -> AgentKind:
    """
    Identify which agent emitted a hook payload.

    Args:
        payload (dict[str, Any]): Parsed hook JSON payload from stdin.

    Returns:
        AgentKind: `"antigravity"` for Antigravity camelCase payloads,
            otherwise `"codex"`.
    """
    if "conversationId" in payload or "hookEventName" in payload:
        return "antigravity"
    return "codex"


def is_codex_cli_session(transcript_path: str | None) -> bool:
    """
    Return whether a Codex transcript belongs to a CLI session.

    Args:
        transcript_path (str | None): Path to the Codex session transcript.

    Returns:
        bool: Whether the session was started from the CLI.
    """
    if not transcript_path:
        return False

    path = Path(transcript_path)
    if not path.is_file():
        return False

    with path.open(encoding="utf-8") as transcript:
        metadata = json.loads(transcript.readline())
    # Codex names the TUI client codex-tui and sets codex_exec as the exec originator.
    # ref: https://github.com/openai/codex/blob/8b8fa7276f3da289108512d673303eeacc5bcff3/codex-rs/tui/src/lib.rs#L562
    # ref: https://github.com/openai/codex/blob/8b8fa7276f3da289108512d673303eeacc5bcff3/codex-rs/exec/src/lib.rs#L241
    return metadata["payload"]["originator"] in {
        "codex-tui",
        "codex_exec",
    }


def is_antigravity_cli_session(
    transcript_path: str | None,
    artifact_dir: str | None,
) -> bool:
    """
    Return whether an Antigravity hook payload belongs to a CLI (`agy`) session.

    Args:
        transcript_path (str | None): Path to the Antigravity transcript.
        artifact_dir (str | None): Path to the Antigravity artifact directory.

    Returns:
        bool: Whether the session uses the `antigravity-cli` app data directory.
    """
    # Antigravity uses distinct app data directories per surface:
    # antigravity-cli (CLI), antigravity (App), and antigravity-ide (IDE).
    for raw_path in (transcript_path, artifact_dir):
        if raw_path and "antigravity-cli" in Path(raw_path).parts:
            return True
    return False


def parse_hook_context(payload: dict[str, Any]) -> tuple[AgentKind, HookContext | None]:
    """
    Resolve repository and session context from a parsed hook JSON payload.

    Args:
        payload (dict[str, Any]): Parsed hook payload.

    Returns:
        tuple[AgentKind, HookContext | None]: Detected agent and resolved
            context, or None outside a CLI session with a Git working tree.
    """
    agent = detect_agent(payload)
    if agent == "antigravity":
        if not is_antigravity_cli_session(
            payload.get("transcriptPath"),
            payload.get("artifactDirectoryPath"),
        ):
            return agent, None

        raw_cwd = payload.get("cwd")
        if not raw_cwd:
            workspace_paths = payload.get("workspacePaths")
            if isinstance(workspace_paths, list) and workspace_paths:
                raw_cwd = workspace_paths[0]
        session_id = payload.get("conversationId")
        if not raw_cwd or not session_id:
            return agent, None

        root = git_worktree_root(Path(raw_cwd))
        if root is None:
            return agent, None

        invocation_num = (
            payload.get("invocationNum", 0)
            if payload.get("hookEventName") == "PreInvocation"
            or "invocationNum" in payload
            or "initialNumSteps" in payload
            else None
        )
        return agent, HookContext(
            agent=agent,
            root=root,
            session_dir=git_cache_dir(root) / str(session_id),
            invocation_num=invocation_num,
        )

    # ref: https://developers.openai.com/codex/hooks#common-input-fields
    if not is_codex_cli_session(payload.get("transcript_path")):
        return agent, None

    raw_cwd = payload.get("cwd")
    session_id = payload.get("session_id")
    if not raw_cwd or not session_id:
        return agent, None

    root = git_worktree_root(Path(raw_cwd))
    if root is None:
        return agent, None

    return agent, HookContext(
        agent=agent,
        root=root,
        session_dir=git_cache_dir(root) / str(session_id),
        turn_id=payload.get("turn_id"),
    )


def read_hook_context() -> tuple[AgentKind, HookContext | None]:
    """
    Read and parse hook context from stdin.

    Returns:
        tuple[AgentKind, HookContext | None]: Detected agent and resolved
            context, or None outside a CLI session with a Git working tree.
    """
    payload = json.load(sys.stdin)
    return parse_hook_context(payload)


def resolve_capture_turn_dir(context: HookContext) -> Path | None:
    """
    Resolve the turn directory to capture a baseline into.

    Args:
        context (HookContext): Resolved hook context.

    Returns:
        Path | None: Turn directory to capture, or None when an Antigravity turn
            already captured its baseline on an earlier model invocation.
    """
    if context.agent == "codex":
        if not context.turn_id:
            return None
        return context.session_dir / context.turn_id

    active_turn_path = context.session_dir / ACTIVE_TURN_FILE
    if active_turn_path.exists() and context.invocation_num != 0:
        return None
    return context.session_dir / uuid.uuid4().hex


def write_active_turn(session_dir: Path, turn_id: str) -> None:
    """
    Record the active turn ID for agents without a turn_id hook field.

    Args:
        session_dir (Path): Cache directory for the current session.
        turn_id (str): Newly created turn directory name.
    """
    session_dir.mkdir(parents=True, exist_ok=True)
    (session_dir / ACTIVE_TURN_FILE).write_text(turn_id, encoding="utf-8")


def write_session_status(session_dir: Path, message: str) -> None:
    """
    Persist the latest turn-diff status message for a session.

    Args:
        session_dir (Path): Cache directory for the current session.
        message (str): Status line message to display after the turn finishes.
    """
    session_dir.mkdir(parents=True, exist_ok=True)
    (session_dir / STATUS_FILE).write_text(message, encoding="utf-8")


def clear_session_status(session_dir: Path) -> None:
    """
    Remove any previously saved turn-diff status message for a session.

    Args:
        session_dir (Path): Cache directory for the current session.
    """
    (session_dir / STATUS_FILE).unlink(missing_ok=True)


def read_session_status(session_dir: Path) -> str | None:
    """
    Read the latest turn-diff status message for a session, if present.

    Args:
        session_dir (Path): Cache directory for the current session.

    Returns:
        str | None: Saved status message, or None when absent or unreadable.
    """
    try:
        message = (session_dir / STATUS_FILE).read_text(encoding="utf-8").strip()
    except OSError:
        return None
    return message or None


def resolve_stop_turn_dir(context: HookContext) -> Path | None:
    """
    Resolve the turn directory to finalize when a turn stops.

    Args:
        context (HookContext): Resolved hook context.

    Returns:
        Path | None: Turn directory containing the baseline, or None when no
            active turn was recorded.
    """
    if context.agent == "codex":
        if not context.turn_id:
            return None
        return context.session_dir / context.turn_id

    active_turn_path = context.session_dir / ACTIVE_TURN_FILE
    if not active_turn_path.is_file():
        return None
    turn_id = active_turn_path.read_text(encoding="utf-8").strip()
    active_turn_path.unlink(missing_ok=True)
    if turn_id in {"", ".", ".."} or "/" in turn_id or "\\" in turn_id:
        return None
    return context.session_dir / turn_id
