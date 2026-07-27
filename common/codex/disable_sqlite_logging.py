import sqlite3
import subprocess
import sys
from pathlib import Path


def main():
    """Disable inserts into Codex's diagnostic log database."""
    codex_is_running = (
        subprocess.run(
            ["pgrep", "-i", "codex"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )
    if codex_is_running:
        raise SystemExit(
            "Quit all Codex processes before running disable_sqlite_logging.py."
        )

    database_path = Path(sys.argv[1])
    if not database_path.exists():
        print(
            "Codex logging database not found. Start and quit Codex, then run this installer again."
        )
        return

    with sqlite3.connect(database_path) as connection:
        connection.execute(
            """
            CREATE TRIGGER IF NOT EXISTS block_log_inserts
            BEFORE INSERT ON logs
            BEGIN
                SELECT RAISE(IGNORE);
            END;
            """
        )


if __name__ == "__main__":
    main()
