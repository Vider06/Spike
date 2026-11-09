# Legacy JSON-configured lexer

This document describes the previous JSON-configured lexer implementation.
It is retained only while existing API clients migrate.

Spike 0.2 phase one is specified in [LEXER-PHASE-1.md](LEXER-PHASE-1.md).
New frontend code must use the SPARK package `Spike_Lexer` and the public
`Spike_API.Lex_Source` entry point. The old `Lexer_Config`,
`Dynamic_Lexer`, and `Token_Stream` packages are compatibility-only and are
not the language-definition source of truth.

The JSON verb table belongs to phase two. It describes instruction operand
forms and flags; it must not control recognition of the phase-one lexical
forms.
