# Spike public API

## Purpose

`Spike_API` is the stable Ada-facing boundary between toolchain clients and the current implementation. The future Spike Manager should call this package instead of depending directly on frontend implementation packages.

The API is deliberately implemented in Ada 2022, matching the toolchain. SPARK contracts remain attached to the underlying units where they are currently supported; the dynamic lexer and this facade are not claimed to be fully SPARK-proved.

## Current surface

| API | Responsibility |
|---|---|
| `API_Version` | Public API compatibility version |
| `Load_Lexer_Configuration` | Load token definitions from the language configuration |
| `Validate_Lexer_Configuration` | Validate caller-provided JSON definitions |
| `Tokenize_Source` | Invoke the JSON-driven frontend lexer |
| `Peek_Token` | Inspect a token without consuming it |
| `Next_Token` | Consume and return the next token |
| `Position` / `Remaining` | Inspect stream progress |
| `Reset` | Reset stream iteration |

The facade owns a private stream handle and returns `Token_Info`, so clients do not need to manipulate the internal token-stream representation.

## Error behavior

The API preserves the existing typed exceptions from its implementation dependencies:

- `Lexer_Config.Config_Error` for invalid configuration documents or files.
- `Dynamic_Lexer.Lexical_Error` for source text that cannot be tokenized.
- `Token_Stream.End_Of_Stream` when peeking or consuming beyond the stream.
- `Token_Stream.Invalid_Stream` if an internal stream invariant is violated.

Callers should handle these errors at their application boundary. The API does not silently convert malformed input into partial output.

## Client integration

- Ada clients, including the future Manager, link against `Spike_API`.
- `spike.gpr` includes `src/api` and the API contract test.
- CI compiles and executes `test_spike_api` on every push.
- Python CI scripts currently orchestrate the build and run the API test executable. They do not link to Ada directly. If a Python script later needs runtime API calls, add a versioned process adapter or C ABI rather than duplicating toolchain behavior in Python.

## Compatibility policy

`API_Version` is independent from the language version and package version. Breaking changes to exported types or behavior require an API version change. New optional operations should be additive whenever practical.
