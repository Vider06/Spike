# Spike public API

## Purpose

`Spike_API` is the stable Ada-facing boundary between toolchain clients and the current implementation. The future Spike Manager should call this package instead of depending directly on frontend implementation packages. The Manager remains a later component; this facade is only the in-process API.

The API is implemented in Ada 2022. It exposes the SPARK lexer through a bounded token buffer and does not expose internal lexer implementation details.

## Current surface

| API | Responsibility |
|---|---|
| `API_Version` | Public API compatibility version |
| `Tokenize_Source` | Tokenize source into a typed token list |
| `Is_Successful` | Check whether tokenization produced a diagnostic |
| `Failure` | Retrieve the structured diagnostic |
| `Text_Of` | Resolve a token's source span against the original source |
| `Peek_Token` | Inspect a token without consuming it |
| `Next_Token` | Consume and return the next token |
| `Position` / `Remaining` | Inspect stream progress |
| `Reset` | Reset stream iteration |

Every token has a kind, zero-based byte offset, byte length, and one-based line/column. The original lexeme is not duplicated in the token buffer; clients use `Text_Of` with the original source.

## Error behavior

Lexical failures are returned as a structured `Diagnostic` with phase, stable code, and source location. `Lexer_Diagnostics.Format` renders the shared human-readable form, for example `LEX002 at 1:1: unterminated quoted text`. `End_Of_Stream` is raised only when a caller peeks or consumes beyond the successful token list.

The API does not silently discard malformed input or present a partial token list as successful.

## Client integration

- Ada clients, including the future Manager, link against `Spike_API`.
- `spike.gpr` includes `src/api` and the API contract test.
- CI compiles and executes `test_spike_api` on every push.
- Python CI scripts orchestrate the build and run the API test executable. They do not link to Ada directly. If a Python script later needs runtime API calls, add a versioned process adapter or C ABI rather than duplicating toolchain behavior in Python.

## Compatibility policy

`API_Version` is independent from the language version and package version. The token-kind and diagnostic surface changed with the Phase 1 lexer replacement, so the API version is now `1.1`. Breaking changes to exported types or behavior require an API version change. New optional operations should be additive whenever practical.
