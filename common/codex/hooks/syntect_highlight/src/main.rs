use std::env;
use std::io::{self, Read};
use std::process;
use std::sync::OnceLock;

use syntect::easy::HighlightLines;
use syntect::highlighting::{Color as SyntectColor, FontStyle, Style as SyntectStyle};
use syntect::parsing::SyntaxSet;
use syntect::util::LinesWithEndings;
use two_face::theme::EmbeddedThemeName;

static SYNTAX_SET: OnceLock<SyntaxSet> = OnceLock::new();

fn syntax_set() -> &'static SyntaxSet {
    SYNTAX_SET.get_or_init(two_face::syntax::extra_newlines)
}

fn syntax_theme() -> syntect::highlighting::Theme {
    two_face::theme::extra()
        .get(EmbeddedThemeName::CatppuccinMocha)
        .clone()
}

fn convert_syntect_color(color: SyntectColor) -> String {
    format!("38;2;{};{};{}", color.r, color.g, color.b)
}

fn convert_style(style: SyntectStyle) -> String {
    let mut parts = Vec::new();
    if style.font_style.contains(FontStyle::BOLD) {
        parts.push("1".to_string());
    }
    parts.push(convert_syntect_color(style.foreground));
    // Like Codex TUI, skip backgrounds, italic, and underline so syntax styles do
    // not fight the diff row background or terminal rendering quirks.
    // Codex TUI returns ratatui spans here. This hook emits ANSI because less -R
    // consumes terminal bytes rather than ratatui styles.
    format!("\x1b[{}m", parts.join(";"))
}

fn highlight_code(extension: &str, code: &str) -> Option<String> {
    let syntax = syntax_set().find_syntax_by_extension(extension)?;
    let theme = syntax_theme();
    let mut highlighter = HighlightLines::new(syntax, &theme);
    let mut output = String::new();

    for line in LinesWithEndings::from(code) {
        let ranges = highlighter.highlight_line(line, syntax_set()).ok()?;
        for (style, text) in ranges {
            let text = text.trim_end_matches(['\n', '\r']);
            if text.is_empty() {
                continue;
            }
            output.push_str(&convert_style(style));
            output.push_str(text);
            output.push_str("\x1b[22;39m");
        }
        output.push('\n');
    }

    Some(output)
}

fn main() {
    let mut args = env::args().skip(1);
    let Some(extension) = args.next() else {
        eprintln!("usage: codex-syntect-highlight <extension>");
        process::exit(2);
    };

    let mut code = String::new();
    if let Err(error) = io::stdin().read_to_string(&mut code) {
        eprintln!("failed to read stdin: {error}");
        process::exit(1);
    }

    match highlight_code(&extension, &code) {
        Some(output) => print!("{output}"),
        None => process::exit(1),
    }
}
