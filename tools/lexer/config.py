"""Strict JSON configuration loading and validation for the dynamic lexer."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

SUPPORTED_MATCHERS = {
    "literal",
    "identifier",
    "decimal_integer",
    "hex_integer",
    "binary_integer",
    "quoted_string",
    "whitespace",
    "line_comment",
}


class ConfigError(ValueError):
    """Raised when a lexer definition document is invalid."""


@dataclass(frozen=True, slots=True)
class TokenDefinition:
    name: str
    matcher: str
    value: str | None = None
    priority: int = 0
    emit: bool = True


@dataclass(frozen=True, slots=True)
class LexerConfig:
    schema_version: str
    definitions: tuple[TokenDefinition, ...]


def validate_config(document: Any) -> LexerConfig:
    """Validate a JSON-decoded document and return an immutable config."""
    if not isinstance(document, dict):
        raise ConfigError("configuration root must be an object")
    unknown_root = set(document) - {"schema_version", "tokens"}
    if unknown_root:
        raise ConfigError(f"unknown configuration fields: {', '.join(sorted(unknown_root))}")
    if document.get("schema_version") != "1.0":
        raise ConfigError("schema_version must be exactly '1.0'")
    raw_definitions = document.get("tokens")
    if not isinstance(raw_definitions, list) or not raw_definitions:
        raise ConfigError("'tokens' must be a non-empty array")

    definitions: list[TokenDefinition] = []
    names: set[str] = set()
    literal_keys: set[tuple[str, int]] = set()

    for index, raw in enumerate(raw_definitions):
        prefix = f"tokens[{index}]"
        if not isinstance(raw, dict):
            raise ConfigError(f"{prefix} must be an object")
        unknown_fields = set(raw) - {"name", "matcher", "value", "priority", "emit"}
        if unknown_fields:
            raise ConfigError(
                f"{prefix} has unknown fields: {', '.join(sorted(unknown_fields))}"
            )
        name = raw.get("name")
        matcher = raw.get("matcher")
        priority = raw.get("priority", 0)
        emit = raw.get("emit", True)
        value = raw.get("value")

        if (
            not isinstance(name, str)
            or not name
            or not name.isascii()
            or not name.isidentifier()
        ):
            raise ConfigError(f"{prefix}.name must be an ASCII identifier")
        if name in names:
            raise ConfigError(f"duplicate token name: {name}")
        names.add(name)
        if not isinstance(matcher, str) or matcher not in SUPPORTED_MATCHERS:
            raise ConfigError(
                f"{prefix}.matcher must be one of: {', '.join(sorted(SUPPORTED_MATCHERS))}"
            )
        if isinstance(priority, bool) or not isinstance(priority, int):
            raise ConfigError(f"{prefix}.priority must be an integer")
        if not isinstance(emit, bool):
            raise ConfigError(f"{prefix}.emit must be boolean")

        needs_value = matcher in {"literal", "line_comment"}
        if needs_value and (not isinstance(value, str) or not value):
            raise ConfigError(
                f"{prefix}.value must be a non-empty string for {matcher}"
            )
        if not needs_value and value is not None:
            raise ConfigError(f"{prefix}.value is only valid for literal/line_comment")
        if matcher == "literal":
            key = (value, priority)
            if key in literal_keys:
                raise ConfigError(
                    f"ambiguous literal {value!r} has duplicate priority {priority}"
                )
            literal_keys.add(key)
        definitions.append(TokenDefinition(name, matcher, value, priority, emit))

    if not any(item.emit for item in definitions):
        raise ConfigError("at least one token definition must emit tokens")
    return LexerConfig("1.0", tuple(definitions))


def load_config(path: str | Path) -> LexerConfig:
    """Load UTF-8 JSON and validate it before it reaches the lexer."""
    try:
        document = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ConfigError(f"cannot load lexer configuration: {exc}") from exc
    return validate_config(document)
