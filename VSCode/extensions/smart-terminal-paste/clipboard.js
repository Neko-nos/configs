const { execFile } = require("node:child_process");
const { promisify } = require("node:util");

const execFileAsync = promisify(execFile);
const detectImageScript = `
ObjC.import("AppKit");
$.NSImage.canInitWithPasteboard($.NSPasteboard.generalPasteboard) ? "image" : "text";
`;

async function clipboardContainsImage() {
    const { stdout } = await execFileAsync("/usr/bin/osascript", [
        "-l",
        "JavaScript",
        "-e",
        detectImageScript,
    ]);
    return stdout.trim() === "image";
}

module.exports = { clipboardContainsImage };
