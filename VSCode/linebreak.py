import argparse
import re
from pathlib import Path

# HTMLのtagを用いているものは簡単なものしか自分は使わないので複雑なものは割愛
# ref: https://qiita.com/Qiita/items/c686397e4a0f4f11683d
# ref: https://docs.github.com/ja/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
tab_pattern = re.compile(r"\t")
br_pattern = re.compile(r"<br>$")
comment_pattern = re.compile(r"<!-- .* -->")
code_pattern = re.compile(r"```")
title_pattern = re.compile(r"#+ ")
alert_pattern = re.compile(r"> \[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]")
quote_pattern = re.compile(r"(> )+")
image_pattern = re.compile(r"(!\[.*\]\(.+\))|(<img .* src=.+>)")
table_pattern = re.compile(r"((\|:-+:\|)+)|((\|:-+\|-+:\|)+\|:-+:\|)")
table_cell_pattern = re.compile(r"\| .* \|")
# ネストも考慮する
list_pattern = re.compile(r"(\s*((\*|\+|-) )|(\d+\. ))")
# lists用の最小のindent幅は3なので、それ以下は通常のテキストとみなす(実際に、日本語で段落の始まりのスペースも2で収まる)
# indent幅でより正確に決められるが複雑なのでUser側に任せる
list_text_pattern = re.compile(r" {3,}.*")
# listsの中にさらに特殊記号がある場合にも対応する
# (ちなみにre.searchはテキスト内の記号とマッチしてしまう可能性があるので面倒でもこっちのほうが良い)
list_comment_pattern = re.compile(r" {3,}<!-- .* -->")
list_code_pattern = re.compile(r" {3,}```")
list_title_pattern = re.compile(r" {3,}#+")
list_quote_pattern = re.compile(r" {3,}(> )+")
list_image_pattern = re.compile(r" {3,}(!\[.*\]\(.+\))|(<img .* src=.+>)")
list_table_pattern = re.compile(r" {3,}((\|:-+:\|)+)|((\|:-+\|-+:\|)+\|:-+:\|)")
list_table_cell_pattern = re.compile(r" {3,}\| .* \|")
list_indent_pattern = re.compile(r" {3,}")


def main(filepath):
    filepath = Path(filepath)
    if filepath.suffix != ".md":
        raise ValueError("`filepath` must be the path of a markdown file.")

    with open(filepath, mode="r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    # <br>を入れるかを決めていく
    new_lines = []
    num_lines = len(lines)
    is_code = False
    is_alert = False
    is_table = False
    is_list = False
    for idx, line in enumerate(lines):
        if idx == (num_lines - 1):
            # 一般的にはfileの最後の行は空行になっているがそうでない場合も考慮し、書き込み時にも空行にしておく
            if line:
                next_line = ""
            else:
                new_lines.append(line)
                break
        else:
            next_line = lines[idx + 1]

        # 既に<br>等があると重なってしまうので削っておく
        # 2つ半角スペースがあるのはtrailling spaces拡張機能との相性が良くない
        line = re.sub(br_pattern, "", line)
        line = line.rstrip()
        next_line = re.sub(br_pattern, "", next_line)
        next_line = next_line.rstrip()
        # 先頭にtabがある場合にlistsのネストの処理が面倒なのでspaceに変換させる
        line = re.sub(tab_pattern, "    ", line)
        next_line = re.sub(tab_pattern, "    ", next_line)
        # 特殊な段落を作るものを処理
        if is_code:
            new_lines.append(line + "\n")
            end = re.sub(list_code_pattern, "", line) if is_list else re.sub(code_pattern, "", line)
            if not end:
                is_code = False
            continue
        elif is_alert:
            current_result = list_quote_pattern.match(line) if is_list else quote_pattern.match(line)
            next_result = list_quote_pattern.match(next_line) if is_list else quote_pattern.match(next_line)
            if current_result and next_result:
                new_lines.append(line + "\n")
                continue
            elif current_result:
                new_lines.append(line + "\n")
                # <br>では段落が分けられない
                new_lines.append("\n")
                is_alert = False
                continue
        elif is_table:
            # is_tableになって1回目(つまり2行目)のみtable_patternに該当する
            current_result = (
                (list_table_cell_pattern.match(line) or list_table_pattern.match(line))
                if is_list
                else (table_cell_pattern.match(line) or table_pattern.match(line))
            )
            next_result = list_table_cell_pattern.match(next_line) if is_list else table_cell_pattern.match(next_line)
            if current_result and next_result:
                new_lines.append(line + "\n")
                continue
            elif current_result:
                new_lines.append(line + "\n")
                # <br>では段落が分けられない
                new_lines.append("\n")
                continue
        elif is_list:
            # indentが必要なだけで基本的な処理は後ろの処理とあまり変わらない
            if list_comment_pattern.match(line) or list_comment_pattern.match(next_line):
                new_lines.append(line + "\n")
            elif list_title_pattern.match(line) or list_title_pattern.match(next_line):
                new_lines.append(line + "\n")
            elif list_image_pattern.match(line) or list_image_pattern.match(next_line):
                new_lines.append(line + "\n")
            elif list_code_pattern.match(line):
                new_lines.append(line + "\n")
                is_code = True
            elif alert_pattern.match(line):
                new_lines.append(line + "\n")
                is_alert = True
            elif list_table_cell_pattern.match(line) and list_table_pattern.match(next_line):
                new_lines.append(line + "\n")
                is_table = True
            elif list_quote_pattern.match(line) and list_quote_pattern.match(next_line):
                new_lines.append(line + "\n")
            elif list_quote_pattern.match(line):
                new_lines.append(line + "\n")
                new_lines.append("\n")
            elif list_text_pattern.match(line) and list_text_pattern.match(next_line):
                new_lines.append(line + "<br>" + "\n")
            elif list_text_pattern.match(line) and (
                list_pattern.match(next_line)
                or list_comment_pattern.match(next_line)
                or list_code_pattern.match(next_line)
                or list_title_pattern.match(next_line)
                or list_quote_pattern.match(next_line)
                or list_image_pattern.match(next_line)
            ):
                new_lines.append(line + "\n")
            elif not list_indent_pattern.match(next_line):
                new_lines.append(line + "\n")
                is_list = False
            continue

        # 空行に関しては何もしない
        if not line or not next_line:
            new_lines.append(line + "\n")
        elif comment_pattern.match(line) or comment_pattern.match(next_line):
            new_lines.append(line + "\n")
        elif title_pattern.match(line) or title_pattern.match(next_line):
            new_lines.append(line + "\n")
        elif image_pattern.match(line) or image_pattern.match(next_line):
            new_lines.append(line + "\n")
        elif code_pattern.match(line):
            new_lines.append(line + "\n")
            is_code = True
            is_alert = False
            is_table = False
            is_list = False
        elif alert_pattern.match(line):
            new_lines.append(line + "\n")
            is_alert = True
            is_code = False
            is_table = False
            is_list = False
        elif table_cell_pattern.match(line) and table_pattern.match(next_line):
            new_lines.append(line + "\n")
            is_table = True
            is_code = False
            is_alert = False
            is_list = False
        elif quote_pattern.match(line) and quote_pattern.match(next_line):
            new_lines.append(line + "\n")
        elif quote_pattern.match(line):
            new_lines.append(line + "\n")
            new_lines.append("\n")
        # listsの処理
        elif list_pattern.match(line) and (
            list_pattern.match(next_line)
            or list_comment_pattern.match(next_line)
            or list_code_pattern.match(next_line)
            or list_title_pattern.match(next_line)
            or list_quote_pattern.match(next_line)
            or list_image_pattern.match(next_line)
        ):
            new_lines.append(line + "\n")
            is_list = True
        elif list_pattern.match(line) and list_text_pattern.match(next_line):
            new_lines.append(line + "<br>" + "\n")
            is_list = True
        # indentがない場合に、基本的にlists一行で終わらせることはないので
        # その後もlistsのblockにあるとみなして考える
        elif list_pattern.match(line):
            new_lines.append(line + "<br>" + "\n")
        elif list_pattern.match(next_line):
            new_lines.append(line + "\n")
            new_lines.append("\n")
        elif (
            code_pattern.match(next_line)
            or title_pattern.match(next_line)
            or alert_pattern.match(next_line)
            or quote_pattern.match(next_line)
            or image_pattern.match(next_line)
            or table_cell_pattern.match(next_line)
        ):
            new_lines.append(line + "\n")
        else:
            new_lines.append(line + "<br>" + "\n")

    with open(filepath, mode="w", encoding="utf-8") as f:
        f.writelines(new_lines)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file", required=True, type=str, help="The path of the markdown file.")
    args = parser.parse_args()
    main(args.file)
