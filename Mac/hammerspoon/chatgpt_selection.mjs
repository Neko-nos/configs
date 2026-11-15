#!/usr/bin/env node

import { spawn } from "node:child_process";

function applySelectionColor() {
    // Embedded websites keep their own styles.
    if (!location.href.startsWith("app://-/")) return;

    function apply() {
        // Match the visible Terminal highlight, without ChatGPT's accent darkening.
        document.documentElement.style.setProperty(
            "--color-background-text-selection",
            "#819afb",
            "important",
        );
    }

    if (document.documentElement) apply();
    else document.addEventListener("DOMContentLoaded", apply, { once: true });
}

async function main() {
    // Inherited pipes keep the control connection private; no debugging port is opened.
    const app = spawn(
        "/Applications/ChatGPT.app/Contents/MacOS/ChatGPT",
        ["--remote-debugging-pipe"],
        {
            stdio: ["ignore", "ignore", "ignore", "pipe", "pipe"],
        },
    );
    const pending = new Map();
    const attached = new Set();
    const source = `(${applySelectionColor.toString()})()`;
    let sequence = 0;
    let buffer = "";

    function send(method, params, sessionId) {
        return new Promise((resolve, reject) => {
            const id = ++sequence;
            pending.set(id, { resolve, reject });
            app.stdio[3].write(
                `${JSON.stringify({ id, method, params, sessionId })}\0`,
            );
        });
    }

    async function attach(target) {
        if (
            target.type !== "page" ||
            !target.url.startsWith("app://-/") ||
            attached.has(target.targetId)
        )
            return;
        attached.add(target.targetId);
        const { sessionId } = await send("Target.attachToTarget", {
            targetId: target.targetId,
            flatten: true,
        });
        await send("Page.enable", {}, sessionId);
        await send(
            "Page.addScriptToEvaluateOnNewDocument",
            { source },
            sessionId,
        );
        await send("Runtime.evaluate", { expression: source }, sessionId);
    }

    app.stdio[4].setEncoding("utf8");
    app.stdio[4].on("data", (chunk) => {
        buffer += chunk;
        let boundary = buffer.indexOf("\0");
        while (boundary !== -1) {
            const message = JSON.parse(buffer.slice(0, boundary));
            buffer = buffer.slice(boundary + 1);
            if (message.id) {
                const request = pending.get(message.id);
                pending.delete(message.id);
                if (message.error)
                    request.reject(new Error(message.error.message));
                else request.resolve(message.result);
            } else if (
                message.method === "Target.targetCreated" ||
                message.method === "Target.targetInfoChanged"
            ) {
                attach(message.params.targetInfo).catch(console.error);
            }
            boundary = buffer.indexOf("\0");
        }
    });
    app.on("error", (error) => {
        console.error(error.message);
        process.exitCode = 1;
    });
    app.on("exit", (code) => {
        process.exitCode = code;
    });

    await send("Target.setDiscoverTargets", { discover: true });
}

await main();
