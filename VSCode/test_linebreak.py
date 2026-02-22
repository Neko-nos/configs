"""Regression tests for linebreak.py."""

import unittest

from VSCode.linebreak import process_markdown


class ProcessMarkdownTests(unittest.TestCase):
    """Tests for Markdown line-break conversion behavior."""

    def convert(self, content: str) -> str:
        """Run conversion with the same split strategy as the CLI."""
        return "".join(process_markdown(content.splitlines()))

    def test_plain_paragraph_inserts_br(self):
        """It inserts <br> between consecutive plain lines."""
        content = "first line\nsecond line\n\nthird line\n"
        expected = "first line<br>\nsecond line\n\nthird line\n"

        self.assertEqual(self.convert(content), expected)

    def test_table_without_alignment_markers_is_preserved(self):
        """It preserves a standard table and adds no <br>."""
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

        self.assertEqual(output, content)
        self.assertNotIn("<br>", output)

    def test_table_with_alignment_markers_is_preserved(self):
        """It preserves aligned separator rows and adds no <br>."""
        content = "| Left | Right |\n|:-----|------:|\n| a | b |\n"

        output = self.convert(content)

        self.assertEqual(output, content)
        self.assertNotIn("<br>", output)

    def test_title_comment_and_image_lines_do_not_get_br(self):
        """It keeps block-like boundaries separated by plain newlines."""
        content = (
            "# Heading\n<!-- keep block -->\n![chart](chart.png)\nnext paragraph\n"
        )

        self.assertEqual(self.convert(content), content)

    def test_quote_block_keeps_newlines_and_breaks_after_block(self):
        """It preserves quote lines and inserts a blank line after the quote block."""
        content = "> q1\n> q2\nafter quote\n"
        expected = "> q1\n> q2\n\nafter quote\n"

        self.assertEqual(self.convert(content), expected)

    def test_alert_block_uses_br_inside_and_blank_line_after(self):
        """It inserts <br> between alert lines and separates the following paragraph."""
        content = "> [!NOTE]\n> alert line 1\n> alert line 2\nafter alert\n"
        expected = "> [!NOTE]\n> alert line 1<br>\n> alert line 2\n\nafter alert\n"

        self.assertEqual(self.convert(content), expected)

    def test_fenced_code_block_is_preserved(self):
        """It does not inject <br> inside fenced code blocks."""
        content = "```\nprint('x')\n```\nafter code\n"
        expected = "```\nprint('x')\n```\nafter code\n"

        self.assertEqual(self.convert(content), expected)

    def test_list_continuation_uses_br_for_item_line(self):
        """It keeps list continuation behavior for wrapped list items."""
        content = "- item\n  continuation\nnext para\n"
        expected = "- item<br>\n  continuation\nnext para\n"

        self.assertEqual(self.convert(content), expected)


if __name__ == "__main__":
    unittest.main()
