# Spike Phase 1 lexer

## Output contract

The lexer returns a bounded token list. Each token contains:

- token kind;
- zero-based byte offset and byte length in the original source;
- one-based line and column;
- indentation width for a newline token.

The original text is not copied into every token. The public API resolves a token's lexeme against the original source span.

## Token forms

| Kind | Form |
|---|---|
| `WORD` | A non-empty printable atom, stopping at whitespace, brackets, comma, quote, or a comment marker |
| `QUOTED_TEXT` | Double-quoted text; a backslash escapes the next character; a quoted token cannot cross a line break |
| `LEFT_BRACKET` | `[` |
| `RIGHT_BRACKET` | `]` |
| `COMMA` | `,` |
| `FLAG` | `--name`, with an ASCII letter or underscore first and then ASCII letters, digits, underscores, or hyphens |
| `NEWLINE_INDENT` | LF, CR, or CRLF followed by the spaces/tabs indenting the next line |
| `COMMENT` | `^^` through the end of the current line |

Horizontal spaces and tabs between tokens are skipped. CRLF is one newline. Tabs count as one source column and one indentation unit; columns are byte-oriented so they match token offsets.

## Shape checks

This phase deliberately does not know the names or operand requirements of Spike verbs. It checks only lexical shape:

- quoted text must terminate on the same line;
- flags must have a valid name;
- square brackets must balance and cannot be empty;
- whitespace immediately after `[` or immediately before `]` is rejected;
- a comma must have a valid token on both sides and horizontal whitespace immediately before and after it;
- control characters outside quoted text/comments are rejected.

A comma is valid only when horizontal whitespace appears immediately on both sides. The parser will later determine whether the resulting token sequence is valid for the verb's operand schema.

## Diagnostics

All phases use `Lexer_Types.Diagnostic`: phase, stable code, zero-based byte offset, one-based line, and one-based column. The human-readable format is:

```text
LEX002 at 1:1: unterminated quoted text
```

The code prefix is phase-specific; line and column are available independently of the formatted message. The lexer never silently skips an invalid source character or returns a successful partial token list.

The source limit is 16 MiB and the caller supplies a bounded token buffer (the public API uses 4,096 tokens). Exceeding either limit is a structured diagnostic.

## SPARK boundary

`Lexer_Types`, `Lexer`, and the reusable lexical predicates are written in SPARK-compatible Ada. The JSON loader is not part of this phase. Phase 2's JSON adapter will remain ordinary Ada and produce a validated Ada table before the parser and semantic core consume it.

## Tests

`test_lexer` covers each token form, correct and incorrect bracket/comma/flag/string forms, source positions, CRLF and indentation. `tests/frontend/lexer/golden/basic.spike` and `basic.tokens` form the first source/output golden pair. `fuzz_lexer` runs deterministic malformed ASCII inputs and verifies token-span bounds and ordering for every successful result.
