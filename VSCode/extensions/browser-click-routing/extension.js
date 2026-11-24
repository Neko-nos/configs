const { execFile } = require("node:child_process");
const { promisify } = require("node:util");

const vscode = require("vscode");
const { Terminal } = require("@xterm/headless");

const { indexWrappedLinks } = require("./terminal-links");

function activate(context) {
    const run = promisify(execFile);
    // Restored remote terminals can lack initial dimensions in the workspace host.
    const buffers = new Map();
    const terminalsByProcessId = new Map();
    function terminalBuffer(terminal) {
        if (!buffers.has(terminal)) {
            const dimensions = terminal.dimensions;
            const buffer = new Terminal({
                allowProposedApi: true,
                ...(dimensions && {
                    cols: dimensions.columns,
                    rows: dimensions.rows,
                }),
                scrollback: vscode.workspace
                    .getConfiguration("terminal.integrated")
                    .get("scrollback"),
            });
            const state = { buffer, pending: Promise.resolve() };
            buffers.set(terminal, state);
            void terminal.processId.then((processId) => {
                if (
                    processId !== undefined &&
                    buffers.get(terminal) === state
                ) {
                    state.processId = processId;
                    terminalsByProcessId.set(processId, state);
                }
            });
        }
        return buffers.get(terminal);
    }
    context.subscriptions.push(
        vscode.window.onDidWriteTerminalData(({ terminal, data }) => {
            const state = terminalBuffer(terminal);
            state.pending = state.pending.then(
                () =>
                    new Promise((resolve) => {
                        state.buffer.write(data, () => {
                            state.links = undefined;
                            resolve();
                        });
                    }),
            );
        }),
        vscode.window.onDidChangeTerminalDimensions(
            ({ terminal, dimensions }) => {
                const state = terminalBuffer(terminal);
                state.pending = state.pending.then(() => {
                    state.buffer.resize(dimensions.columns, dimensions.rows);
                    state.links = undefined;
                });
            },
        ),
        vscode.window.onDidCloseTerminal((terminal) => {
            const state = buffers.get(terminal);
            if (
                state?.processId !== undefined &&
                terminalsByProcessId.get(state.processId) === state
            ) {
                terminalsByProcessId.delete(state.processId);
            }
            void state?.pending.then(() => state.buffer.dispose());
            buffers.delete(terminal);
        }),
        {
            dispose() {
                for (const state of buffers.values()) {
                    void state.pending.then(() => state.buffer.dispose());
                }
                terminalsByProcessId.clear();
            },
        },
        vscode.commands.registerCommand(
            "browserClickRouting.provideTerminalLinks",
            async (processId, line) => {
                if (!line.trim()) {
                    return [];
                }
                let state = terminalsByProcessId.get(processId);
                if (!state) {
                    for (const [terminal, candidate] of buffers) {
                        if (candidate.processId !== undefined) {
                            continue;
                        }
                        const id = await terminal.processId;
                        if (
                            id !== undefined &&
                            buffers.get(terminal) === candidate
                        ) {
                            candidate.processId = id;
                            terminalsByProcessId.set(id, candidate);
                        }
                        if (id === processId) {
                            state = candidate;
                            break;
                        }
                    }
                }
                if (!state) {
                    return [];
                }
                await state.pending;
                state.links ??= indexWrappedLinks(state.buffer);
                return state.links.get(line) ?? [];
            },
        ),
        vscode.commands.registerCommand(
            "browserClickRouting.openTerminalLink",
            (uri) =>
                vscode.env.openExternal(vscode.Uri.parse(uri), {
                    allowContributedOpeners: "browserClickRouting.open",
                }),
        ),
        vscode.window.registerExternalUriOpener(
            "browserClickRouting.open",
            {
                canOpenExternalUri() {
                    return vscode.ExternalUriOpenerPriority.Preferred;
                },
                async openExternalUri(uri) {
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
                    if (stdout.trim() === "external") {
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
