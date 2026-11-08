# Dynamic Lexer

Spike's lexer is implemented natively in Ada 2022. The JSON file
`config/lexer/tokens.json` is the source of truth for token definitions:
adding or changing token definitions does not require editing lexer code.

## Architecture

- `Lexer_Config` parses and validates the JSON configuration using
  GNATCOLL.JSON. It rejects unknown fields, unsupported matcher names,
  invalid token identifiers, duplicate names, malformed values, invalid
  priorities, and ambiguous duplicate literals.
- `Dynamic_Lexer` performs deterministic maximal-munch matching. The longest
  match wins; priority breaks length ties. An unresolved equal-priority tie
  is an error. No executable code or arbitrary regular expressions are loaded
  from JSON.
- `Token_Stream` owns the emitted tokens and provides bounded lookahead,
  consumption, expectation, remaining-count, and reset operations. A failed
  expectation does not consume the mismatched token.

## JSON contract

The root object requires `schema_version: "1.0"` and a non-empty `tokens`
array. Each token has a unique ASCII identifier `name`, a supported
`matcher`, optional integer `priority` (default 0), and optional boolean
`emit` (default true). `literal` and `line_comment` require a non-empty
string `value`; other matchers reject `value`.

Supported matchers are `literal`, `identifier`, `decimal_integer`,
`hex_integer`, `binary_integer`, `quoted_string`, `whitespace`, and
`line_comment`. Identifiers and numeric digits are ASCII-defined. Quoted
strings use JSON string escaping and are decoded by the JSON implementation.
Whitespace recognizes space, horizontal tab, carriage return, and line feed.

## Coordinates and errors

Offsets and columns are byte-based (UTF-8 byte offsets), while line numbers
advance on LF. This is explicit so parser diagnostics can map directly to
source buffers. Invalid JSON, invalid definitions, ambiguous matching, and
unrecognized source bytes fail with typed exceptions rather than silently
skipping input.

## Verification boundary

The JSON adapter and dynamic string/container operations are Ada runtime
components. They are not currently claimed as SPARK-proved. The package
boundary is isolated so bounded, proof-oriented lexer state and token-stream
invariants can be moved into SPARK-compatible types without changing the JSON
contract. CI compiles and executes the native Ada lexer tests; the existing
SPARK proof gate remains separate and does not imply lexer proofs.
