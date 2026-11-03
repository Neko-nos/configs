const vscode = require("vscode");

function activate(context) {
    context.subscriptions.push(
        // VS Code forwards link requests to one host; share the workspace host with other providers.
        vscode.window.registerTerminalLinkProvider({
            async provideTerminalLinks({ terminal, line }) {
                const processId = await terminal.processId;
                if (processId === undefined) {
                    return [];
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
