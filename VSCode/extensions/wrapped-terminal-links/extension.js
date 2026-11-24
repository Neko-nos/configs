const vscode = require("vscode");

function activate(context) {
    const processIds = new WeakMap();
    context.subscriptions.push(
        // VS Code forwards link requests to one host; share the workspace host with other providers.
        vscode.window.registerTerminalLinkProvider({
            async provideTerminalLinks({ terminal, line }) {
                if (!line.trim()) {
                    return [];
                }
                let processId = processIds.get(terminal);
                if (processId === undefined) {
                    processId = await terminal.processId;
                    if (processId === undefined) {
                        return [];
                    }
                    processIds.set(terminal, processId);
                }
                // UI and remote hosts expose different Terminal objects for the same process.
                return vscode.commands.executeCommand(
                    "browserClickRouting.provideTerminalLinks",
                    processId,
                    line,
                );
            },
            handleTerminalLink(link) {
                return vscode.commands.executeCommand(
                    "browserClickRouting.openTerminalLink",
                    link.uri,
                );
            },
        }),
    );
}

module.exports = { activate };
