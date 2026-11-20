"""PreToolUse hook to block access to sensitive env, direnv, secrets, and credential files."""

from __future__ import annotations

import itertools
import json
import os
import re
import shlex
import sys
from typing import Any

PATH_ARG_KEYS = frozenset(
    {
        "absolutepath",
        "cwd",
        "directorypath",
        "filepath",
        "imagepaths",
        "path",
        "paths",
        "scriptpath",
        "searchdirectory",
        "searchpath",
        "targetfile",
    }
)
PATTERN_ARG_KEYS = frozenset({"includes", "pattern"})
COMMAND_ARG_KEYS = frozenset({"command", "commandline"})
SCRIPT_ARG_KEYS = frozenset({"script"})

COMMAND_SEPARATORS = frozenset({";", "&&", "||", "|", "&", "\n", "(", ")"})
SHELL_COMMANDS = frozenset({"ash", "bash", "dash", "fish", "ksh", "sh", "zsh"})

HOME_VAR_RE = re.compile(r"\$\{HOME\}|\$HOME(?![A-Za-z0-9_])")
QUOTED_LITERAL_RE = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"|\'([^\']*)\'')
CMD_SUBST_RE = re.compile(r"\$\((.+)\)|`([^`]+)`")
URL_SCHEME_RE = re.compile(r"^[a-zA-Z][a-zA-Z0-9+.-]*://")


def build_rules(home: str) -> tuple[tuple[str, re.Pattern[str]], ...]:
    """
    Build compiled sensitive-path rules mirroring common/claude/settings.json.

    Args:
        home (str): Home directory used to anchor home-relative rules.

    Returns:
        tuple[tuple[str, re.Pattern[str]], ...]: Pairs of (rule_name, regex).
    """
    raw_rules: list[tuple[str, str]] = [
        (".env*", r"(^|/)\.env[^/]*($|/)"),
        (".direnv", r"(^|/)\.direnv($|/)"),
        ("secrets", r"(^|/)secrets($|/)"),
    ]
    home_suffixes = (
        ("~/.netrc", r"\.netrc($|/)"),
        ("~/.aws/credentials", r"\.aws/credentials($|/)"),
        ("~/**/huggingface/token", r"(.+/)?huggingface/token($|/)"),
    )
    homes = dict.fromkeys(
        p.replace("\\", "/").rstrip("/")
        for p in (os.path.normpath(home), os.path.realpath(home))
        if p
    )
    for home_prefix in homes:
        escaped = re.escape(home_prefix)
        raw_rules.extend(
            (name, rf"^{escaped}/{suffix}") for name, suffix in home_suffixes
        )

    return tuple(
        (name, re.compile(pattern, re.IGNORECASE)) for name, pattern in raw_rules
    )


def _expand_home(raw: str, home: str) -> str:
    """
    Expand $HOME, ${HOME}, and leading ~ using the given home directory.

    Args:
        raw (str): Input path string.
        home (str): Home directory path.

    Returns:
        str: Path with home references expanded.
    """
    expanded = HOME_VAR_RE.sub(lambda _: home, raw)
    if expanded == "~":
        return home
    if expanded.startswith(("~/", "~\\")):
        return f"{home}/{expanded[2:]}"
    return expanded


def check_path(
    raw_path: str,
    cwd: str | None,
    home: str,
    rules: tuple[tuple[str, re.Pattern[str]], ...],
) -> str | None:
    """
    Return a deny reason if raw_path matches any sensitive-path rule.

    Args:
        raw_path (str): Candidate path string.
        cwd (str | None): Working directory for resolving relative paths.
        home (str): Home directory for expanding ~ and $HOME.
        rules (tuple[tuple[str, re.Pattern[str]], ...]): Compiled path rules.

    Returns:
        str | None: Denial reason if blocked, or None if allowed.
    """
    target = raw_path.strip()
    if not target or URL_SCHEME_RE.match(target):
        return None

    expanded = _expand_home(target, home)
    normalized = os.path.normpath(expanded)
    candidates = [normalized.replace("\\", "/")]

    abs_path = (
        normalized
        if os.path.isabs(expanded)
        else (os.path.normpath(os.path.join(cwd, expanded)) if cwd else None)
    )
    if abs_path is not None:
        candidates.extend(
            (abs_path.replace("\\", "/"), os.path.realpath(abs_path).replace("\\", "/"))
        )

    for candidate in dict.fromkeys(candidates):
        for rule_name, pattern in rules:
            if pattern.search(candidate):
                return f"Blocked access to protected path '{target}' (matched rule: {rule_name})."
    return None


def _nested_commands(segment: list[str]) -> list[str]:
    """
    Extract nested shell commands from substitutions, eval, or shell -c invocations.

    Args:
        segment (list[str]): Shell tokens for a single command segment.

    Returns:
        list[str]: Nested command strings to inspect recursively.
    """
    nested: list[str] = []
    for idx, token in enumerate(segment):
        nested.extend(
            m.group(1) if m.group(1) is not None else m.group(2)
            for m in CMD_SUBST_RE.finditer(token)
        )
        base = os.path.basename(token)
        if base == "eval" and idx + 1 < len(segment):
            nested.append(" ".join(segment[idx + 1 :]))
        elif base in SHELL_COMMANDS:
            for arg_idx in range(idx + 1, len(segment)):
                arg = segment[arg_idx]
                if arg == "--" or not arg.startswith("-"):
                    break
                is_c_flag = arg == "--command" or (
                    not arg.startswith("--") and "c" in arg[1:]
                )
                if is_c_flag and arg_idx + 1 < len(segment):
                    nested.append(segment[arg_idx + 1])
                    break
    return nested


def inspect_command_line(
    command_line: str,
    cwd: str | None,
    home: str,
    rules: tuple[tuple[str, re.Pattern[str]], ...],
    depth: int = 0,
) -> str | None:
    """
    Inspect a shell command line for references to protected paths.

    Args:
        command_line (str): Raw shell command line.
        cwd (str | None): Effective working directory.
        home (str): Home directory path.
        rules (tuple[tuple[str, re.Pattern[str]], ...]): Compiled path rules.
        depth (int): Current recursion depth for nested shells/substitutions.

    Returns:
        str | None: Denial reason if blocked, or None if allowed.
    """
    if not command_line.strip():
        return None

    lexer = shlex.shlex(command_line, posix=True, punctuation_chars=";|&<>()\n")
    lexer.commenters = ""
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        for part in re.split(r"[\s;|&<>()'\"`]+", command_line):
            for candidate in (part, part.split("=", 1)[1]) if "=" in part else (part,):
                if reason := check_path(candidate, cwd, home, rules):
                    return reason
        return None

    effective_cwd = cwd
    for is_sep, group in itertools.groupby(tokens, COMMAND_SEPARATORS.__contains__):
        if is_sep:
            continue
        segment = list(group)

        for token in segment:
            candidates = [token, token.split("=", 1)[1]] if "=" in token else [token]
            candidates.extend(
                m.group(1) if m.group(1) is not None else m.group(2)
                for m in QUOTED_LITERAL_RE.finditer(token)
            )
            for candidate in candidates:
                if reason := check_path(candidate, effective_cwd, home, rules):
                    return reason

        if depth < 4:
            for inner in _nested_commands(segment):
                if reason := inspect_command_line(
                    inner, effective_cwd, home, rules, depth + 1
                ):
                    return reason

        if segment[0] in {"cd", "pushd"}:
            target = next(
                (a for a in segment[1:] if a != "--" and not a.startswith("-")), None
            )
            if target is None and "-" not in segment[1:]:
                effective_cwd = home
            elif target is not None:
                expanded = _expand_home(target, home)
                effective_cwd = (
                    os.path.normpath(expanded)
                    if os.path.isabs(expanded) or not effective_cwd
                    else os.path.normpath(os.path.join(effective_cwd, expanded))
                )

    return None


def evaluate_payload(
    payload: dict[str, Any], home: str | None = None
) -> dict[str, str]:
    """
    Evaluate an Antigravity PreToolUse payload and return an allow/deny decision.

    Args:
        payload (dict[str, Any]): Parsed hook stdin JSON object.
        home (str | None): Optional home directory override for testing.

    Returns:
        dict[str, str]: Decision object with "decision" and optional "reason".
    """
    tool_call = payload.get("toolCall")
    raw_args = tool_call.get("args") if isinstance(tool_call, dict) else None
    if not isinstance(raw_args, dict):
        return {"decision": "allow"}

    resolved_home = home if home is not None else os.path.expanduser("~")
    rules = build_rules(resolved_home)
    workspaces = payload.get("workspacePaths")
    first_ws = workspaces[0] if isinstance(workspaces, list) and workspaces else None
    cwd = next(
        (
            v
            for v in (
                raw_args.get("Cwd"),
                raw_args.get("cwd"),
                payload.get("cwd"),
                first_ws,
            )
            if isinstance(v, str) and v.strip()
        ),
        None,
    )

    for key, value in raw_args.items():
        norm_key = key.lower().replace("_", "")
        raw_items = (
            [value]
            if isinstance(value, str)
            else value
            if isinstance(value, list)
            else []
        )
        items = [item for item in raw_items if isinstance(item, str)]

        if norm_key in PATH_ARG_KEYS:
            for item in items:
                if reason := check_path(item, cwd, resolved_home, rules):
                    return {"decision": "deny", "reason": reason}
        elif norm_key in PATTERN_ARG_KEYS:
            for item in items:
                if reason := check_path(item, None, resolved_home, rules):
                    return {"decision": "deny", "reason": reason}
        elif norm_key in SCRIPT_ARG_KEYS:
            for item in items:
                for match in QUOTED_LITERAL_RE.finditer(item):
                    literal = (
                        match.group(1) if match.group(1) is not None else match.group(2)
                    )
                    if reason := check_path(literal, cwd, resolved_home, rules):
                        return {"decision": "deny", "reason": reason}
        elif norm_key in COMMAND_ARG_KEYS:
            for item in items:
                if reason := inspect_command_line(item, cwd, resolved_home, rules):
                    return {"decision": "deny", "reason": reason}

    return {"decision": "allow"}


def main() -> int:
    """
    Read a PreToolUse JSON payload from stdin and write the hook decision to stdout.

    Returns:
        int: Process exit status (always 0 after writing valid JSON).
    """
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError as exc:
        response = {
            "decision": "deny",
            "reason": f"Blocked tool call due to invalid hook input JSON: {exc}.",
        }
    else:
        response = (
            evaluate_payload(payload)
            if isinstance(payload, dict)
            else {
                "decision": "deny",
                "reason": "Blocked tool call because hook input payload is not a JSON object.",
            }
        )

    json.dump(response, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
