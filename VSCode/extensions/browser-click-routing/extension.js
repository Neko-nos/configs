const { execFile } = require("node:child_process");
const { promisify } = require("node:util");

const vscode = require("vscode");

function activate(context) {
    const run = promisify(execFile);
    context.subscriptions.push(
        vscode.window.registerExternalUriOpener(
            "browserClickRouting.open",
            {
                canOpenExternalUri() {
                    return vscode.ExternalUriOpenerPriority.Preferred;
                },
                async openExternalUri(uri) {
                    let target = "integrated";
                    if (process.platform === "darwin") {
                        const command = run(
                            "/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs",
                            [
                                "-q",
                                "-c",
                                `return require("vscode_browser").consumeClick(${process.ppid})`,
                            ],
                        );
                        command.child.stdin.end();
                        const { stdout } = await command;
                        target = stdout.trim();
                    }
                    if (target === "external") {
                        // The original click already passed VS Code's trusted-domain check.
                        await run("/usr/bin/open", [uri.toString(true)]);
                    } else {
                        await vscode.commands.executeCommand(
                            "workbench.action.browser.open",
                            uri.toString(true),
                        );
                    }
                },
            },
            {
                schemes: ["http", "https"],
                label: "Open with browser click routing",
            },
        ),
    );
}

module.exports = { activate };
