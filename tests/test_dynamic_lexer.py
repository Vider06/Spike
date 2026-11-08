"""Tests for JSON validation, dynamic lexing, and token-stream behavior."""

import unittest
from pathlib import Path

from tools.lexer import DynamicLexer, LexicalError, load_config, validate_config
from tools.lexer.config import ConfigError

ROOT = Path(__file__).resolve().parents[1]


class LexerConfigTests(unittest.TestCase):
    def test_repository_configuration_loads(self):
        config = load_config(ROOT / "config/lexer/tokens.json")
        self.assertEqual(config.schema_version, "1.0")
        self.assertGreater(len(config.definitions), 10)

    def test_rejects_duplicate_names(self):
        with self.assertRaises(ConfigError):
            validate_config({
                "schema_version": "1.0",
                "tokens": [
                    {"name": "WORD", "matcher": "identifier"},
                    {"name": "WORD", "matcher": "decimal_integer"},
                ],
            })

    def test_rejects_unknown_fields(self):
        with self.assertRaises(ConfigError):
            validate_config({
                "schema_version": "1.0",
                "tokens": [{"name": "WORD", "matcher": "identifier", "regex": ".*"}],
            })

    def test_rejects_unknown_matcher(self):
        with self.assertRaises(ConfigError):
            validate_config({
                "schema_version": "1.0",
                "tokens": [{"name": "BAD", "matcher": "python"}],
            })

    def test_comment_marker_is_configurable(self):
        config = validate_config({
            "schema_version": "1.0",
            "tokens": [
                {"name": "WORD", "matcher": "identifier"},
                {"name": "COMMENT", "matcher": "line_comment", "value": "#", "emit": False},
                {"name": "SPACE", "matcher": "whitespace", "emit": False},
            ],
        })
        stream = DynamicLexer(config).tokenize("word # comment\nnext")
        self.assertEqual([token.value for token in stream], ["word", "next"])


class DynamicLexerTests(unittest.TestCase):
    def setUp(self):
        self.config = load_config(ROOT / "config/lexer/tokens.json")
        self.lexer = DynamicLexer(self.config)

    def test_tokenizes_values_and_positions(self):
        stream = self.lexer.tokenize('out.term "Hello"\nR0, 42')
        actual = [(token.kind, token.value, token.line, token.column) for token in stream]
        self.assertEqual(actual, [
            ("IDENTIFIER", "out", 1, 1),
            ("DOT", ".", 1, 4),
            ("IDENTIFIER", "term", 1, 5),
            ("STRING", "Hello", 1, 10),
            ("IDENTIFIER", "R0", 2, 1),
            ("COMMA", ",", 2, 3),
            ("INTEGER", "42", 2, 5),
        ])

    def test_reports_unknown_character(self):
        with self.assertRaises(LexicalError) as caught:
            self.lexer.tokenize("@")
        self.assertEqual(caught.exception.line, 1)
        self.assertEqual(caught.exception.column, 1)

    def test_longest_literal_wins(self):
        config = validate_config({
            "schema_version": "1.0",
            "tokens": [
                {"name": "ASSIGN", "matcher": "literal", "value": "="},
                {"name": "EQUAL", "matcher": "literal", "value": "=="},
            ],
        })
        stream = DynamicLexer(config).tokenize("==")
        self.assertEqual([token.kind for token in stream], ["EQUAL"])

    def test_string_escapes(self):
        token = self.lexer.tokenize('"a\\n b"').consume()
        self.assertEqual(token.value, "a\n b")


class TokenStreamTests(unittest.TestCase):
    def test_peek_consume_and_reset(self):
        tokens = DynamicLexer(load_config(ROOT / "config/lexer/tokens.json")).tokenize("a b")
        self.assertEqual(tokens.peek().kind, "IDENTIFIER")
        self.assertEqual(tokens.remaining, 2)
        self.assertEqual(tokens.consume().value, "a")
        self.assertEqual(tokens.peek().value, "b")
        self.assertIsNone(tokens.peek(1))
        tokens.reset()
        self.assertEqual(tokens.position, 0)

    def test_expect_reports_mismatch(self):
        stream = DynamicLexer(load_config(ROOT / "config/lexer/tokens.json")).tokenize("name")
        with self.assertRaises(ValueError):
            stream.expect("INTEGER")


if __name__ == "__main__":
    unittest.main()
