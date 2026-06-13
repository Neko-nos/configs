"""Regression tests for linebreak.py."""

from VSCode.linebreak import process_markdown


class TestProcessMarkdown:
    """Tests for Markdown line-break conversion behavior."""

    def convert(self, content: str) -> str:
        """Run conversion with the same split strategy as the CLI."""
        return "".join(process_markdown(content.splitlines()))

    def test_plain_paragraph_inserts_hard_break(self):
        """It inserts a hard break between consecutive plain lines."""
        content = "first line\nsecond line\n\nthird line\n"
        expected = "first line\\\nsecond line\n\nthird line\n"

        assert self.convert(content) == expected

    def test_table_without_alignment_markers_is_preserved(self):
        """It preserves a standard table and adds no hard break."""
        content = (
            "| Metric | Value |\n"
            "|---|---|\n"
            "| accuracy | 1.0 |\n"
            "| latency_ms | 42 |\n"
            "\n"
            "| Env | Status |\n"
            "|---|---|\n"
            "| dev | pass |\n"
            "| prod | pass |\n"
        )

        output = self.convert(content)

        assert output == content
        assert "\\\n" not in output

    def test_table_with_alignment_markers_is_preserved(self):
        """It preserves aligned separator rows and adds no hard break."""
        content = "| Left | Right |\n|:-----|------:|\n| a | b |\n"

        output = self.convert(content)

        assert output == content
        assert "\\\n" not in output

    def test_title_comment_and_image_lines_do_not_get_hard_break(self):
        """It keeps block-like boundaries separated by plain newlines."""
        content = (
            "# Heading\n<!-- keep block -->\n![chart](chart.png)\nnext paragraph\n"
        )

        assert self.convert(content) == content

    def test_quote_block_keeps_newlines_and_breaks_after_block(self):
        """It inserts hard breaks inside quotes and a blank line afterward."""
        content = "> q1\n> q2\nafter quote\n"
        expected = "> q1\\\n> q2\n\nafter quote\n"

        assert self.convert(content) == expected

    def test_quote_block_without_space_marker_works(self):
        """It treats '>' without a following space as quote markers."""
        content = ">q1\n>q2\nafter quote\n"
        expected = ">q1\\\n>q2\n\nafter quote\n"

        assert self.convert(content) == expected

    def test_quote_block_three_lines_adds_hard_break_between_each_pair(self):
        """It adds a hard break between each adjacent quote line."""
        content = "> a\n> b\n> c\n"
        expected = "> a\\\n> b\\\n> c\n"

        assert self.convert(content) == expected

    def test_quote_with_fenced_code_block_is_preserved(self):
        """It keeps quoted fenced code blocks free from injected hard breaks."""
        content = (
            "> before\n"
            "> ```shell\n"
            "> echo one\n"
            "> echo two\n"
            "> ```\n"
            "> after\n"
            "\n"
            "next line\n"
        )

        assert self.convert(content) == content

    def test_quote_fenced_code_block_adds_blank_line_before_plain_text(self):
        """It inserts a blank line when a quoted fenced code block is followed by plain text."""
        content = "> ```\n> echo one\n> ```\nafter\n"
        expected = "> ```\n> echo one\n> ```\n\nafter\n"

        assert self.convert(content) == expected

    def test_quote_marker_only_line_is_supported(self):
        """It handles lines that are only a quote marker."""
        content = ">\n> next\nafter\n"
        expected = ">\\\n> next\n\nafter\n"

        assert self.convert(content) == expected

    def test_alert_block_uses_hard_break_inside_and_blank_line_after(self):
        """It inserts hard breaks in alerts and separates the next paragraph."""
        content = "> [!NOTE]\n> alert line 1\n> alert line 2\nafter alert\n"
        expected = "> [!NOTE]\n> alert line 1\\\n> alert line 2\n\nafter alert\n"

        assert self.convert(content) == expected

    def test_alert_with_fenced_code_block_is_preserved(self):
        """It keeps alert fenced code blocks free from injected hard breaks."""
        content = (
            "> [!CAUTION]\n"
            "> before\n"
            "> ```shell\n"
            "> echo one\n"
            "> echo two\n"
            "> ```\n"
            "> after\n"
            "\n"
            "next line\n"
        )

        assert self.convert(content) == content

    def test_alert_fenced_code_block_adds_blank_line_before_plain_text(self):
        """It inserts a blank line after alert fenced code before plain text."""
        content = "> [!NOTE]\n> ```\n> echo one\n> ```\nafter\n"
        expected = "> [!NOTE]\n> ```\n> echo one\n> ```\n\nafter\n"

        assert self.convert(content) == expected

    def test_fenced_code_block_is_preserved(self):
        """It does not inject hard breaks inside fenced code blocks."""
        content = "```\nprint('x')\n```\nafter code\n"
        expected = "```\nprint('x')\n```\nafter code\n"

        assert self.convert(content) == expected

    def test_fenced_code_block_with_heading_like_lines_is_preserved(self):
        """It preserves fenced code even if inner lines look like Markdown headings."""
        content = (
            "```bash\n"
            "# setup section\n"
            'APP_NAME="demo"\n'
            'if [ -n "$APP_NAME" ]; then\n'
            '  echo "- not a markdown list"\n'
            "fi\n"
            "```\n"
        )

        output = self.convert(content)

        assert output == content
        assert "\\\n" not in output

    def test_fenced_code_block_keeps_literal_br_text(self):
        """It keeps a literal '<br>' text at line end inside fenced code."""
        content = "```\nvalue=<br>\n```\n"

        assert self.convert(content) == content

    def test_html_comment_without_spaces_is_treated_as_comment(self):
        """It detects comments even when there are no spaces around content."""
        content = "before\n<!--comment-->\nafter\n"

        assert self.convert(content) == content

    def test_list_continuation_uses_hard_break_for_item_line(self):
        """It keeps list continuation behavior for wrapped list items."""
        content = "- item\n  continuation\nnext para\n"
        expected = "- item\\\n  continuation\nnext para\n"

        assert self.convert(content) == expected

    def test_existing_br_tag_is_migrated_to_hard_break(self):
        """It migrates a legacy br tag without duplicating the break marker."""
        content = "first line<br>\nsecond line\n"
        expected = "first line\\\nsecond line\n"

        assert self.convert(content) == expected

    def test_existing_hard_break_is_idempotent(self):
        """It keeps one trailing backslash when processing an existing hard break."""
        content = "first line\\\nsecond line\n"

        assert self.convert(content) == content

    def test_existing_hard_break_with_trailing_spaces_is_normalized(self):
        """It removes spaces after an existing trailing backslash."""
        content = "first line\\  \nsecond line\n"
        expected = "first line\\\nsecond line\n"

        assert self.convert(content) == expected
