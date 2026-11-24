function indexWrappedLinks(terminal) {
    const lines = [];
    const regions = new Map();
    const buffer = terminal.buffer.active;
    const cell = buffer.getNullCell();
    for (let row = 0; row < buffer.length; row++) {
        const bufferLine = buffer.getLine(row);
        const text = bufferLine.translateToString(true);
        let line = lines.at(-1);
        if (!bufferLine.isWrapped || !line) {
            line = { text: "", links: [] };
            lines.push(line);
        }
        const offset = line.text.length;
        line.text += text;

        const borders = [];
        // tmux panes share physical rows; aligned borders delimit independent text streams.
        if (/[│┃║]/u.test(text)) {
            for (let column = 0; column < terminal.cols; column++) {
                const char = bufferLine.getCell(column, cell).getChars();
                if (
                    /[│┃║]/u.test(char) &&
                    [row - 1, row + 1].some(
                        (neighbor) =>
                            buffer
                                .getLine(neighbor)
                                ?.getCell(column, cell)
                                ?.getChars() === char,
                    )
                ) {
                    borders.push(column);
                }
            }
        }
        let left = 0;
        for (const right of [...borders, terminal.cols]) {
            const key = `${left}:${right}`;
            if (!regions.has(key)) {
                regions.set(key, { width: right - left, rows: [] });
            }
            let end = right;
            while (
                end > left &&
                !bufferLine
                    .getCell(end - 1, cell)
                    .getChars()
                    .trim()
            ) {
                end--;
            }
            regions.get(key).rows.push({
                source: line,
                row,
                text: bufferLine.translateToString(true, left, right),
                base:
                    offset +
                    bufferLine.translateToString(false, 0, left).length,
                right:
                    end > left
                        ? end -
                          1 +
                          bufferLine.getCell(end - 1, cell).getWidth() -
                          left
                        : 0,
                wrapped: bufferLine.isWrapped && borders.length === 0,
            });
            left = right + 1;
        }
    }

    for (const region of regions.values()) {
        linkWrappedRows(region.rows, region.width);
    }

    const index = new Map();
    for (const line of lines) {
        if (line.links.length > 1) {
            line.links.sort((a, b) => a.startIndex - b.startIndex);
        }
        const previous = index.get(line.text);
        if (!previous) {
            index.set(line.text, line.links);
        } else if (
            (previous.length > 0 || line.links.length > 0) &&
            JSON.stringify(previous) !== JSON.stringify(line.links)
        ) {
            // The provider supplies text without a row number, so ambiguous repeated rows must defer.
            index.set(line.text, []);
        }
    }
    return index;
}

function linkWrappedRows(lines, width) {
    const chunks = [];
    let length = 0;
    let current = "";
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const previous = lines[i - 1];
        const trimmed = line.text.trimStart();
        const indent = line.text.length - trimmed.length;
        // TUI renderers can reserve an indented margin and the final terminal column,
        // or word-wrap long URLs at a hyphen/plus breakpoint before the right edge.
        const continues =
            previous &&
            line.row === previous.row + 1 &&
            (line.wrapped ||
                (trimmed &&
                    !/^https?:\/\//i.test(trimmed) &&
                    (previous.right >= width - indent - 1 ||
                        ((current.endsWith("-") || current.endsWith("+")) &&
                            /^(?:[a-z0-9_~%]|[-/][a-z0-9_~%])/i.test(trimmed) &&
                            /https?:\/\/[^\s<>"'`\u2500-\u257f]*[-+]$/i.test(
                                current,
                            )))));
        line.offset = continues && !line.wrapped ? indent : 0;
        if (!continues) {
            chunks.push("\n");
            length += 1;
            current = "";
        }
        const slice = line.text.slice(line.offset);
        line.start = length;
        chunks.push(slice);
        length += slice.length;
        line.end = length;
        current += slice;
    }

    const text = chunks.join("");
    let lineIndex = 0;
    for (const match of text.matchAll(
        /https?:\/\/[^\s<>"'`\u2500-\u257f]+/gi,
    )) {
        let uri = match[0].replace(/[.,;:!]+$/, "");
        for (const [opening, closing] of [
            ["(", ")"],
            ["[", "]"],
            ["{", "}"],
        ]) {
            while (
                uri.endsWith(closing) &&
                uri.split(closing).length > uri.split(opening).length
            ) {
                uri = uri.slice(0, -1);
            }
        }
        const end = match.index + uri.length;
        while (
            lineIndex < lines.length &&
            lines[lineIndex].end <= match.index
        ) {
            lineIndex++;
        }
        const parts = [];
        for (let j = lineIndex; j < lines.length && lines[j].start < end; j++) {
            parts.push(lines[j]);
        }
        // Native soft wraps already work; only replace links crossing application line breaks.
        if (
            parts.length === 0 ||
            parts.every((part) => part.source === parts[0].source) ||
            !URL.canParse(uri)
        ) {
            continue;
        }
        for (const line of parts) {
            const start = Math.max(match.index, line.start);
            line.source.links.push({
                startIndex: line.base + start - line.start + line.offset,
                length: Math.min(end, line.end) - start,
                uri,
                tooltip: uri,
            });
        }
    }
}

module.exports = { indexWrappedLinks };
