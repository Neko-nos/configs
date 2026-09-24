import json
import subprocess


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


def main() -> None:
    """
    Refresh shared sessions before opening the local resume picker.

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

        # Import missing sessions first, including those without a saved name.
        # Empty search then reconciles existing rows and their update timestamps.
        for search in ({}, {"searchTerm": ""}):
            # Fetch 100 sessions per page to reduce app-server round trips.
            params = {"limit": 100, "modelProviders": [], **search}
            while True:
                page = request(server, "thread/list", params)
                if page["nextCursor"] is None:
                    break
                params["cursor"] = page["nextCursor"]


if __name__ == "__main__":
    main()
