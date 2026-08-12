const { execFile } = require("node:child_process");
const { promisify } = require("node:util");

const execFileAsync = promisify(execFile);
const readImageScript = `
ObjC.import("AppKit");

function clipboardImageAsBase64() {
    const pasteboard = $.NSPasteboard.generalPasteboard;
    if (!$.NSImage.canInitWithPasteboard(pasteboard)) {
        return "";
    }

    const image = $.NSImage.alloc.initWithPasteboard(pasteboard);
    const bitmap = $.NSBitmapImageRep.imageRepWithData(image.TIFFRepresentation);
    const png = bitmap.representationUsingTypeProperties(
        $.NSBitmapImageFileTypePNG,
        $({}),
    );
    return ObjC.unwrap(png.base64EncodedStringWithOptions(0));
}

clipboardImageAsBase64();
`;

async function readClipboardImage() {
    const { stdout } = await execFileAsync("/usr/bin/osascript", [
        "-l",
        "JavaScript",
        "-e",
        readImageScript,
    ], {
        // Screenshots can exceed Node's 1 MiB child-process output limit after base64 encoding.
        maxBuffer: 64 * 1024 * 1024,
    });
    const encodedImage = stdout.trim();
    return encodedImage === "" ? undefined : Buffer.from(encodedImage, "base64");
}

module.exports = { readClipboardImage };
