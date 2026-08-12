const { randomUUID } = require("node:crypto");

const vscode = require("vscode");

const { readClipboardImage } = require("./clipboard");

function activate(context) {
    const command = vscode.commands.registerCommand("smartTerminalPaste.paste", async () => {
        const image = await readClipboardImage();

        if (image === undefined) {
            await vscode.commands.executeCommand("workbench.action.terminal.paste");
            return;
        }

        if (vscode.env.remoteName === undefined) {
            await vscode.commands.executeCommand("workbench.action.terminal.sendSequence", {
                text: "\u0016",
            });
            return;
        }

        const workspaceUri = vscode.workspace.workspaceFolders[0].uri;
        const imagePath = `/tmp/codex-clipboard-${randomUUID()}.png`;
        const imageUri = workspaceUri.with({ path: imagePath });
        await vscode.workspace.fs.writeFile(imageUri, image);
        await vscode.commands.executeCommand("workbench.action.terminal.sendSequence", {
            text: `\u001b[200~${imagePath}\u001b[201~`,
        });
    });
    context.subscriptions.push(command);
}

module.exports = { activate };
