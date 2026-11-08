"""Configuration-driven lexical analysis for Spike bootstrap tooling."""

from .config import LexerConfig, TokenDefinition, load_config, validate_config
from .engine import DynamicLexer, LexicalError
from .stream import Token, TokenStream

__all__ = [
    "DynamicLexer",
    "LexerConfig",
    "LexicalError",
    "Token",
    "TokenDefinition",
    "TokenStream",
    "load_config",
    "validate_config",
]
