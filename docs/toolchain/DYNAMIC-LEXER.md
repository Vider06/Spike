# Dynamic Lexer

Spike's lexer is implemented natively in Ada 2022 under `src/frontend/lexer/`. The JSON file
`src/leng/lexer/tokens.json` is the source of truth for token definitions.
Adding a keyword, operator, delimiter, comment prefix, or token name is a
configuration change: it does not require a lexer source-code change.

## Architecture

- `Lexer_Config` parses and validates the JSON configuration using
  GNATCOLL.JSON. It rejects unknown fields, unsupported matcher primitives,
  invalid token identifiers, duplicate names, malformed values, invalid
  priorities, and ambiguous equal-priority definitions.
- `Dynamic_Lexer` compiles the validated definitions into dispatch indexes.
  One-byte literals use a character bucket; longer literals and comment
  prefixes use a two-byte prefix bucket. Generic matcher definitions are
  reduced to the highest-priority definition for their matcher kind. The
  lexer therefore does not scan every configured rule at every source byte.
- Matching is deterministic maximal munch: the longest match wins; priority
  breaks length ties. Equal-length, equal-priority candidates are rejected.
  No executable code, user callbacks, or arbitrary regular expressions are
  loaded from JSON.
- `Token_Stream` validates token kinds, non-empty lexemes, byte-span lengths,
  and monotonically ordered non-overlapping spans when constructed. Its
  cursor is private and bounded. `peek` is non-consuming, `consume` advances
  exactly one token, `expect` leaves the cursor unchanged on mismatch,
  `reset` returns to the beginning, and lookahead past EOF raises
  `End_Of_Stream`.

## JSON contract and extensibility

The root object requires `schema_version: "1.0"` and a non-empty `tokens`
array. Each token has a unique ASCII identifier `name`, a supported
`matcher`, optional integer `priority` (default 0), and optional boolean
`emit` (default true). `literal` and `line_comment` require a non-empty
string `value`; other matchers reject `value`.

Supported matcher primitives are `literal`, `identifier`,
`decimal_integer`, `hex_integer`, `binary_integer`, `quoted_string`,
`whitespace`, and `line_comment`. These primitives are the stable
recognition vocabulary; the token vocabulary itself is entirely JSON-owned.
For example, a language keyword is an ordinary `literal` entry with a
configured priority above `identifier`. The lexer contains no Spike keyword
table and does not know the spelling of language instructions or reserved
words. JSON can add, remove, rename, or reprioritize token definitions without
changing Ada code. Adding a *new matcher primitive* is an engine/schema
extension, not a token-definition-only change.

Identifiers and numeric digits are ASCII-defined. Quoted strings use JSON
string escaping and are decoded by GNATCOLL.JSON. Whitespace recognizes
space, horizontal tab, carriage return, and line feed. The configuration
limits the number of token definitions to 4,096; the source input limit is
16 MiB.

## Coordinates and errors

Offsets and columns are byte-based (UTF-8 byte offsets), while line numbers
advance on LF. This is explicit so parser diagnostics can map directly to
source buffers. Invalid JSON, invalid definitions, ambiguous matching,
malformed quoted strings, and unrecognized source bytes fail with typed
exceptions rather than silently skipping input.

## Tests and fuzzing

The Ada test suite covers JSON validation, custom JSON-defined keywords,
operator maximal munch, generic matcher priority, escaped and unterminated
strings, ASCII boundaries, CRLF positions, EOF, lookahead, reset, mismatch
non-consumption, and invalid token-stream construction. The deterministic
fuzz executable sends 2,000 reproducible arbitrary ASCII inputs through the
lexer and checks every successfully emitted token's span and stream ordering.
It is a regression fuzz harness, not a replacement for long-running coverage-
guided fuzzing.

## Verification boundary

The JSON adapter, GNATCOLL.JSON calls, dynamic matcher dispatch, and vector
operations are Ada runtime components and are not claimed as SPARK-proved.
The ASCII character classes, identifier predicates, maximal-munch ordering,
source-span validity, span ordering, bounded source-offset advancement, and
token cursor advancement are specified in `Lexer_Properties` with contracts.
The lexer and token stream call these contracted helpers at their boundaries. The manifest `src/leng/language.json` indexes the token data and its schema.
GNATprove checks the SPARK package and its proof harness in CI. Passing those
proofs establishes only those stated properties; it does not formally verify
the complete dynamic lexer, JSON parser, or vector-backed stream.
