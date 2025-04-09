terminals = [
    "gnome-terminal-server.Gnome-terminal",
]

def is_terminal(window_title: str, include_vscode: bool = True):
    if include_vscode and window_title == "code.Code":
        return True
    for terminal in terminals:
        if window_title == terminal:
            return True
    return False

window_title = window.get_active_class()
if is_terminal(window_title=window_title, include_vscode=False):
    keyboard.send_keys("<ctrl>+<shift>+c")
else:
    keyboard.send_keys("<ctrl>+c")
