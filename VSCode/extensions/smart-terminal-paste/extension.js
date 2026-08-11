const vscode = require("vscode");

const { clipboardContainsImage } = require("./clipboard");

function activate(context) {
    const command = vscode.commands.registerCommand("smartTerminalPaste.paste", async () => {
        let containsImage = false;
        try {
            containsImage = await clipboardContainsImage();
        } catch {
            // Text paste is the safe fallback when macOS clipboard inspection is unavailable.
        }

        if (containsImage) {
            await vscode.commands.executeCommand("workbench.action.terminal.sendSequence", {
                text: "\u0016",
            });
            return;
        }

        await vscode.commands.executeCommand("workbench.action.terminal.paste");
    });
    context.subscriptions.push(command);
}

module.exports = { activate };
