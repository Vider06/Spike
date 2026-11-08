"""Generic maximal-munch lexer driven entirely by validated JSON definitions."""

from __future__ import annotations

import json
from dataclasses import dataclass

from .config import LexerConfig, TokenDefinition
from .stream import Token, TokenStream


@dataclass(frozen=True, slots=True)
class _Match:
    definition: TokenDefinition
    lexeme: str
    value: str
    length: int


class LexicalError(ValueError):
    def __init__(self, message: str, *, offset: int, line: int, column: int):
        super().__init__(f"{message} at {line}:{column} (offset {offset})")
        self.offset = offset
        self.line = line
        self.column = column


class DynamicLexer:
    def __init__(self, config: LexerConfig):
        self._definitions = config.definitions

    @staticmethod
    def _identifier_start(char: str) -> bool:
        return char == "_" or char.isalpha()

    @staticmethod
    def _identifier_continue(char: str) -> bool:
        return char == "_" or char.isalnum()

    def _match(
        self, source: str, offset: int, line: int, column: int
    ) -> _Match | None:
        candidates: list[_Match] = []
        for definition in self._definitions:
            result = self._match_definition(definition, source, offset)
            if result is not None:
                candidates.append(result)
        if not candidates:
            return None
        candidates.sort(
            key=lambda item: (item.length, item.definition.priority),
            reverse=True,
        )
        if (
            len(candidates) > 1
            and candidates[0].length == candidates[1].length
            and candidates[0].definition.priority
            == candidates[1].definition.priority
        ):
            raise LexicalError(
                "ambiguous token definitions",
                offset=offset,
                line=line,
                column=column,
            )
        return candidates[0]

    def _match_definition(
        self, definition: TokenDefinition, source: str, offset: int
    ) -> _Match | None:
        remaining = source[offset:]
        matcher = definition.matcher
        lexeme = ""

        if matcher == "literal":
            assert definition.value is not None
            if not remaining.startswith(definition.value):
                return None
            lexeme = definition.value
        elif matcher == "identifier":
            if not remaining or not self._identifier_start(remaining[0]):
                return None
            end = 1
            while end < len(remaining) and self._identifier_continue(remaining[end]):
                end += 1
            lexeme = remaining[:end]
        elif matcher == "decimal_integer":
            end = 0
            while end < len(remaining) and remaining[end].isdigit():
                end += 1
            if end == 0:
                return None
            lexeme = remaining[:end]
        elif matcher in {"hex_integer", "binary_integer"}:
            prefix = "0x" if matcher == "hex_integer" else "0b"
            if not remaining.lower().startswith(prefix):
                return None
            valid = "0123456789abcdefABCDEF" if matcher == "hex_integer" else "01"
            end = 2
            while end < len(remaining) and remaining[end] in valid:
                end += 1
            if end == 2:
                return None
            lexeme = remaining[:end]
        elif matcher == "whitespace":
            if not remaining or not remaining[0].isspace():
                return None
            end = 1
            while end < len(remaining) and remaining[end].isspace():
                end += 1
            lexeme = remaining[:end]
        elif matcher == "line_comment":
            assert definition.value is not None
            if not remaining.startswith(definition.value):
                return None
            end = len(remaining)
            newline = remaining.find("\n")
            if newline >= 0:
                end = newline
            lexeme = remaining[:end]
        elif matcher == "quoted_string":
            if not remaining.startswith('"'):
                return None
            end = 1
            escaped = False
            while end < len(remaining):
                char = remaining[end]
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    end += 1
                    raw = remaining[:end]
                    try:
                        value = json.loads(raw)
                    except ValueError:
                        return None
                    return _Match(definition, raw, value, end)
                end += 1
            return None
        else:
            return None

        return _Match(definition, lexeme, lexeme, len(lexeme))

    def tokenize(self, source: str) -> TokenStream:
        tokens: list[Token] = []
        offset = 0
        line = 1
        column = 1
        while offset < len(source):
            match = self._match(source, offset, line, column)
            if match is None:
                raise LexicalError(
                    f"unrecognized character {source[offset]!r}",
                    offset=offset,
                    line=line,
                    column=column,
                )
            definition = match.definition
            if definition.emit:
                tokens.append(
                    Token(
                        definition.name,
                        match.lexeme,
                        match.value,
                        offset,
                        offset + match.length,
                        line,
                        column,
                    )
                )
            consumed = source[offset : offset + match.length]
            newlines = consumed.count("\n")
            if newlines:
                line += newlines
                column = len(consumed.rsplit("\n", 1)[-1]) + 1
            else:
                column += match.length
            offset += match.length
        return TokenStream(tokens)
