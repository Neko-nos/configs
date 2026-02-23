import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Literal


# HTMLをMarkdownで使うことはあまりないので割愛
# ref: https://qiita.com/Qiita/items/c686397e4a0f4f11683d
# ref: https://docs.github.com/ja/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
@dataclass
class Patterns:
    # 先頭のtab以外はインデント処理に関係ないので無視する
    tab: re.Pattern = re.compile(r"^\t")
    br_tag: re.Pattern = re.compile(r"<br>$")
    comment: re.Pattern = re.compile(r"<!--.*-->")
    code: re.Pattern = re.compile(r"```")
    title: re.Pattern = re.compile(r"#+ ")
    alert: re.Pattern = re.compile(r"> \[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]")
    quote: re.Pattern = re.compile(r"^(>\s?)+")
    image: re.Pattern = re.compile(r"(!\[.*\]\(.+\))|(<img .* src=.+>)")
    table: re.Pattern = re.compile(r"^\|?(?:\s*:?-{3,}:?\s*\|)+\s*$")
    table_cell: re.Pattern = re.compile(r"^\|.*\|$")
    list_item: re.Pattern = re.compile(r"\s*(\*|\+|-|(\d+\.)) ")
    # ネストに必要なindentでのwhitespaceの最小値は2(- で2文字)
    list_indent_prefix: re.Pattern = re.compile(r"^( {2,})")


@dataclass
class Status:
    is_code: bool = False
    is_quote_code: bool = False
    is_alert: bool = False
    is_alert_code: bool = False
    is_table: bool = False
    is_list: bool = False

    def show_statuses(self):
        if self.is_list:
            if self.is_code:
                print("list and code")
            elif self.is_alert:
                print("list and alert")
            elif self.is_table:
                print("list and table")
            else:
                print("list")
        elif self.is_code:
            print("code")
        elif self.is_alert:
            print("alert")
        elif self.is_table:
            print("table")
        else:
            print("normal")

    def reset_block(self):
        # listだけは他のブロックと共存できるのでFalseにしない
        self.is_code = False
        self.is_quote_code = False
        self.is_alert = False
        self.is_alert_code = False
        self.is_table = False

    def update(
        self,
        status: Literal["code", "alert", "table", "list"],
        unset_list: bool = False,
    ):
        self.reset_block()
        setattr(self, f"is_{status}", True)
        if unset_list:
            self.is_list = False


def strip_quote_prefix(patterns: Patterns, line: str) -> str:
    """Remove the leading quote marker(s) from a line."""
    return patterns.quote.sub("", line, count=1)


def is_quote_code_fence_line(patterns: Patterns, line: str) -> bool:
    """Return True when a quote line starts or ends a fenced code block."""
    if patterns.quote.match(line) is None:
        return False
    return patterns.code.match(strip_quote_prefix(patterns, line)) is not None


def get_newline_suffix(
    status: Status,
    patterns: Patterns,
    line: str,
    next_line: str,
    unset_list: bool,
    is_next_line_list: bool = False,
) -> Literal["", "\n", "\n\n", "<br>\n"]:
    is_quote_code_line = is_quote_code_fence_line(patterns, line)
    is_next_quote_code_line = is_quote_code_fence_line(patterns, next_line)

    # 後で変更をするので、status.is_listの状態を保存しておく
    prev_status_list = status.is_list
    # listが終了しているのに他の条件分岐に引っかかって変更できないことがあるのでここで設定しておく
    # 他のブロックは優先的に処理されるのでここで考える必要はない
    if not is_next_line_list:
        status.is_list = False
    # 複数の空行が連続している時、<br>と\n\nによる改行が重複するので\n\nの方を無くす
    if not line and not next_line:
        return ""
    elif not line or not next_line:
        return "\n"
    # Detect fenced code before heading/comment checks; otherwise a code fence
    # followed by "#" can be misclassified as a heading transition.
    elif patterns.code.match(line):
        status.update("code", unset_list=unset_list)
        status.is_quote_code = False
        return "\n"
    elif is_quote_code_line:
        status.update("code", unset_list=unset_list)
        status.is_quote_code = True
        return "\n"
    elif patterns.comment.match(line) or patterns.comment.match(next_line):
        return "\n"
    elif patterns.title.match(line) or patterns.title.match(next_line):
        return "\n"
    elif patterns.image.match(line) or patterns.image.match(next_line):
        return "\n"
    elif patterns.alert.match(line):
        status.update("alert", unset_list=unset_list)
        return "\n"
    elif patterns.table_cell.match(line) and patterns.table.match(next_line):
        status.update("table", unset_list=unset_list)
        return "\n"
    elif patterns.quote.match(line) and is_next_quote_code_line:
        return "\n"
    # Treat quote bodies like normal wrapped text and force explicit line breaks.
    elif patterns.quote.match(line) and patterns.quote.match(next_line):
        return "<br>" + "\n"
    elif patterns.quote.match(line):
        return "\n\n"
    # alert blockは他の要素内に作ることができないのでここでは考慮しなくて良い (GitHub Markdown)
    elif patterns.list_item.match(line) and (
        patterns.list_item.match(next_line)
        or patterns.comment.match(next_line)
        or patterns.code.match(next_line)
        or patterns.title.match(next_line)
        or patterns.quote.match(next_line)
        or patterns.image.match(next_line)
    ):
        # listに設定する
        status.update("list", unset_list=False)
        return "\n"
    # blockを作るものでは無いので通常のテキストが続いていると考えられる
    # ここで、status.is_listの中でこの関数を使う時には文頭にあるindentをなくしてから渡しているので正規表現ではなく引数からlistの終了を予測する必要がある
    elif patterns.list_item.match(line) and is_next_line_list:
        status.update("list", unset_list=False)
        return "<br>" + "\n"
    # 一番外側のlistが終了している
    elif prev_status_list and not is_next_line_list:
        # 全てFalseにする
        status.update("list", unset_list=True)
        return "\n"
    # lineは通常のテキスト
    elif (
        patterns.code.match(next_line)
        or patterns.title.match(next_line)
        or patterns.alert.match(next_line)
        or patterns.quote.match(next_line)
        or patterns.image.match(next_line)
        or patterns.table.match(next_line)
    ):
        return "\n"
    else:
        return "<br>" + "\n"


def process_markdown(lines: list[str]) -> list[str]:
    """Processes a list of Markdown lines and adds <br> tags where needed."""
    patterns = Patterns()
    status = Status()
    new_lines = []
    for idx, line in enumerate(lines):
        # 最後の行は基本的には空行になっているが、そうでない場合は代わりに挿入しておく
        if idx == len(lines) - 1:
            if line:
                next_line = ""
            else:
                new_lines.append(line)
                break
        else:
            next_line = lines[idx + 1]

        # 最初の改行に使われる記号等を削除する
        # Keep literal "<br>" in code fences because it may be code text, not Markdown.
        if status.is_code:
            line = line.rstrip()
            next_line = next_line.rstrip()
        else:
            line = patterns.br_tag.sub("", line).rstrip()
            next_line = patterns.br_tag.sub("", next_line).rstrip()
        # indentはwhitespaceで数えているのでtabも変換しておく
        line = patterns.tab.sub(" " * 4, line)
        next_line = patterns.tab.sub(" " * 4, next_line)

        # 特別なブロックを作るものをまずは処理する
        if status.is_code:
            new_lines.append(line + "\n")
            if status.is_list:
                # indentの部分を取り除いて考えれば通常の場合の正規表現を使い回せる
                line_for_code_end = patterns.list_indent_prefix.sub("", line)
            else:
                line_for_code_end = line

            if status.is_quote_code:
                line_for_code_end = strip_quote_prefix(patterns, line_for_code_end)

            is_code_end = patterns.code.match(line_for_code_end) is not None
            if is_code_end:
                was_quote_code = status.is_quote_code
                status.is_code = False
                status.is_quote_code = False
                # A quoted code fence is still inside a quote block; insert a blank
                # line before plain text to keep block separation consistent.
                if (
                    was_quote_code
                    and next_line
                    and patterns.quote.match(next_line) is None
                ):
                    new_lines.append("\n")
        # alert blockは他の要素内に作ることができない (GitHub Markdown)
        elif status.is_alert:
            # alertの目印となる部分はis_alertの判定に使っていて、この段階ではalert内の要素のみを扱うことになる
            # その為、is_alert_endと違って、現在の行がquote_patternにmatchするかを判定する必要はない(確実にmatchする)
            is_alert_end = patterns.quote.match(next_line) is None

            if status.is_alert_code:
                new_lines.append(line + "\n")
                if is_quote_code_fence_line(patterns, line):
                    status.is_alert_code = False
                    if is_alert_end:
                        # Alert blocks require an empty line to terminate before
                        # following plain text; "<br>" cannot switch block context.
                        if next_line:
                            new_lines.append("\n")
                        status.is_alert = False
            elif is_quote_code_fence_line(patterns, line):
                new_lines.append(line + "\n")
                status.is_alert_code = True
            elif is_quote_code_fence_line(patterns, next_line):
                new_lines.append(line + "\n")
            elif is_alert_end:
                new_lines.append(line + "\n")
                # 既に後ろに空行が来ていたら追加の\nを追加しなくても切り替わる
                if next_line:
                    # <br>ではblockが切り替わらない
                    new_lines.append("\n")
                status.is_alert = False
                status.is_alert_code = False
            else:
                new_lines.append(line + "<br>" + "\n")
        elif status.is_table:
            # is_tableになって1回目(つまり2行目)のみtable_patternに該当する
            if status.is_list:
                line_no_indent = patterns.list_indent_prefix.sub("", line)
                next_line_no_indent = patterns.list_indent_prefix.sub("", next_line)
                is_table_current = patterns.table.match(
                    line_no_indent
                ) or patterns.table_cell.match(line_no_indent)
                is_table_next = patterns.table.match(
                    next_line_no_indent
                ) or patterns.table_cell.match(next_line_no_indent)
            else:
                is_table_current = patterns.table.match(
                    line
                ) or patterns.table_cell.match(line)
                is_table_next = patterns.table.match(
                    next_line
                ) or patterns.table_cell.match(next_line)

            if is_table_current and is_table_next:
                new_lines.append(line + "\n")
            elif is_table_current:
                new_lines.append(line + "\n")
                # <br>では段落が分けられない
                if next_line:
                    new_lines.append("\n")
                status.is_table = False
            else:
                status.is_table = False
                line_no_indent = patterns.list_indent_prefix.sub("", line)
                next_line_no_indent = patterns.list_indent_prefix.sub("", next_line)
                is_next_line_list = next_line != next_line_no_indent
                new_line = line + get_newline_suffix(
                    status,
                    patterns,
                    line_no_indent,
                    next_line_no_indent,
                    unset_list=not status.is_list,
                    is_next_line_list=is_next_line_list,
                )
                new_lines.append(new_line)
        else:
            line_no_indent = patterns.list_indent_prefix.sub("", line)
            next_line_no_indent = patterns.list_indent_prefix.sub("", next_line)
            is_next_line_list = next_line != next_line_no_indent
            new_line = line + get_newline_suffix(
                status,
                patterns,
                line_no_indent,
                next_line_no_indent,
                unset_list=not status.is_list,
                is_next_line_list=is_next_line_list,
            )
            new_lines.append(new_line)

    return new_lines


def main(filepath: str | Path):
    filepath = Path(filepath)
    if filepath.suffix != ".md":
        raise ValueError("`filepath` must be the path of a markdown file.")

    try:
        with open(filepath, mode="r", encoding="utf-8") as f:
            lines = f.read().splitlines()
    except FileNotFoundError:
        print(f"Error: File not found at {filepath}")
        return
    except Exception as e:
        print(f"Error reading file {filepath}: {e}")
        return

    new_content_lines = process_markdown(lines)

    try:
        with open(filepath, mode="w", encoding="utf-8", newline="\n") as f:
            f.writelines(new_content_lines)
        print(f"Successfully processed {filepath}")
    except Exception as e:
        print(f"Error writing file {filepath}: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Adds <br> tags to Markdown paragraphs for explicit line breaks."
    )
    parser.add_argument(
        "-f", "--file", required=True, type=str, help="The path of the markdown file."
    )
    args = parser.parse_args()
    main(args.file)
