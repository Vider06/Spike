"""Immutable token records and a bounded cursor over a token sequence."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True, slots=True)
class Token:
    kind: str
    lexeme: str
    value: str
    start_offset: int
    end_offset: int
    line: int
    column: int


class TokenStream:
    """A deterministic token cursor; EOF is represented by None."""

    def __init__(self, tokens: Iterable[Token]) -> None:
        self._tokens = tuple(tokens)
        self._position = 0

    @property
    def position(self) -> int:
        return self._position

    @property
    def remaining(self) -> int:
        return len(self._tokens) - self._position

    def peek(self, distance: int = 0) -> Token | None:
        if distance < 0:
            raise ValueError("distance cannot be negative")
        index = self._position + distance
        return self._tokens[index] if index < len(self._tokens) else None

    def consume(self) -> Token | None:
        token = self.peek()
        if token is not None:
            self._position += 1
        return token

    def expect(self, kind: str) -> Token:
        token = self.consume()
        if token is None:
            raise ValueError(f"expected {kind}, reached end of token stream")
        if token.kind != kind:
            raise ValueError(
                f"expected {kind}, found {token.kind} at {token.line}:{token.column}"
            )
        return token

    def reset(self) -> None:
        self._position = 0

    def __iter__(self):
        return iter(self._tokens)
