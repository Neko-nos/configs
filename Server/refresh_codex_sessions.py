import json
import os
import sqlite3
import subprocess
from pathlib import Path


def request(server: subprocess.Popen[str], method: str, params: dict) -> dict:
    """
    Send a request to Codex's app server and wait for its response.

    Args:
        server (subprocess.Popen[str]): Running Codex app server with text pipes.
        method (str): App-server method.
        params (dict): Request parameters.

    Returns:
        dict: The method's result.

    Raises:
        RuntimeError: The server rejects the request or exits before replying.
    """
    # Requests are sequential, so one ID is enough to distinguish replies from notifications.
    server.stdin.write(json.dumps({"id": 1, "method": method, "params": params}) + "\n")
    server.stdin.flush()
    for line in server.stdout:
        response = json.loads(line)
        if response.get("id") != 1:
            continue
        if "error" in response:
            raise RuntimeError(response["error"]["message"])
        return response["result"]
    raise RuntimeError("Codex app server exited before replying.")


def refresh_timestamps(database_path: Path) -> None:
    """
    Refresh local picker timestamps from shared session modification times.

    Args:
        database_path (Path): Local Codex session index.

    Raises:
        OSError: A shared session cannot be inspected.
        sqlite3.Error: The local session index cannot be read or updated.
    """
    with sqlite3.connect(f"{database_path.as_uri()}?mode=rw", uri=True) as database:
        rows = database.execute(
            "SELECT id, rollout_path, updated_at_ms FROM threads "
            "WHERE archived = 0 AND source IN ('cli', 'vscode')"
        ).fetchall()
        updates = []
        for session_id, rollout_path, updated_at_ms in rows:
            try:
                modified_ns = Path(rollout_path).stat().st_mtime_ns
            except FileNotFoundError:
                # Another server may have archived the session since it was listed.
                continue
            modified_ms = modified_ns // 1_000_000
            if modified_ms > updated_at_ms:
                updates.append(
                    (modified_ms // 1000, modified_ms, session_id, updated_at_ms)
                )

        # Codex derives these timestamps from the same mtime during full reconciliation.
        # Compare the old value so an active local session's newer write wins the race.
        database.executemany(
            "UPDATE threads SET updated_at = ?, updated_at_ms = ? "
            "WHERE id = ? AND updated_at_ms = ?",
            updates,
        )


def import_sessions(session_ids: set[str]) -> None:
    """
    Import missing shared sessions through Codex's app server.

    Args:
        session_ids (set[str]): Session IDs absent from the local index.

    Raises:
        RuntimeError: The app server rejects a request or exits before replying.
    """
    with subprocess.Popen(
        ["codex", "app-server"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    ) as server:
        request(
            server,
            "initialize",
            {"clientInfo": {"name": "codex_session_refresh", "version": "1"}},
        )
        server.stdin.write('{"method":"initialized"}\n')
        server.stdin.flush()

        # Reading a missing thread imports its metadata without loading a live session.
        for session_id in session_ids:
            request(server, "thread/read", {"threadId": session_id})


def main() -> None:
    """
    Import new shared sessions and refresh local picker timestamps.

    Raises:
        OSError: Shared session files cannot be inspected.
        RuntimeError: The app server rejects a request or exits before replying.
        sqlite3.Error: The local session index cannot be read or updated.
    """
    codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    database_path = Path(os.environ["CODEX_SQLITE_HOME"]).resolve() / "state_5.sqlite"
    indexed_ids = set()
    if database_path.exists():
        with sqlite3.connect(f"{database_path.as_uri()}?mode=ro", uri=True) as database:
            indexed_ids = {row[0] for row in database.execute("SELECT id FROM threads")}

    # Filenames start with rollout-<19-character timestamp>-<36-character thread UUID>.
    # A reverted rollout can append another UUID, so use the original thread ID.
    shared_ids = {
        path.name[28:64] for path in codex_home.glob("sessions/*/*/*/rollout-*.jsonl*")
    }
    missing_ids = shared_ids - indexed_ids
    if missing_ids:
        import_sessions(missing_ids)

    if database_path.exists():
        refresh_timestamps(database_path)


if __name__ == "__main__":
    main()
