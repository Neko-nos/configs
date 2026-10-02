use std::io;

use syntect::easy::HighlightLines;
use syntect::highlighting::{Color as SyntectColor, FontStyle, Style as SyntectStyle, Theme};
use syntect::parsing::SyntaxSet;
use syntect::util::LinesWithEndings;
use two_face::theme::EmbeddedThemeName;

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

fn highlight_code(
    extension: &str,
    code: &str,
    syntax_set: &SyntaxSet,
    theme: &Theme,
) -> Option<String> {
    let syntax = syntax_set.find_syntax_by_extension(extension)?;
    let mut highlighter = HighlightLines::new(syntax, theme);
    let mut output = String::new();

    for line in LinesWithEndings::from(code) {
        let ranges = highlighter.highlight_line(line, syntax_set).ok()?;
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

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let sections: Vec<(Option<String>, Vec<String>)> = serde_json::from_reader(io::stdin().lock())?;
    let syntax_set = two_face::syntax::extra_newlines();
    let themes = two_face::theme::extra();
    let theme = themes.get(EmbeddedThemeName::CatppuccinMocha);
    let highlighted: Vec<Vec<Option<String>>> = sections
        .into_iter()
        .map(|(extension, hunks)| {
            hunks
                .into_iter()
                .map(|code| {
                    extension
                        .as_deref()
                        .and_then(|extension| highlight_code(extension, &code, &syntax_set, theme))
                })
                .collect()
        })
        .collect();
    serde_json::to_writer(io::stdout().lock(), &highlighted)?;
    Ok(())
}
