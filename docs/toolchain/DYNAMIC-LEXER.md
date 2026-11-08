# Dynamic Lexer Architecture

**Status:** Bootstrap implementation; JSON contract 1.0.

Spike's lexical rules are data-driven. The lexer engine does not contain Spike
keywords or instruction names. Token definitions are loaded from a versioned
JSON document, validated, and then used to produce a source-positioned token
stream.

## Components

1. **JSON contract** — `config/lexer/tokens.schema.json` defines the structural
   schema; `config/lexer/tokens.json` is the initial definition set.
2. **Validator** — rejects unsupported schema versions, malformed entries,
   duplicate token names, invalid matcher/value combinations, and ambiguous
   same-priority literals.
3. **Dynamic lexer** — applies configured matchers using maximal munch (longest
   match), then configured priority to break equal-length matches.
4. **Token stream** — immutable token records with kind, lexeme, decoded value,
   source-character offsets, and one-based line/column.

## Supported matcher primitives

The initial safe matcher vocabulary is literal, identifier, decimal integer,
hex integer, binary integer, quoted string, whitespace, and line comment.
Definitions may choose token names, priorities, and whether a match is emitted.
The JSON format intentionally does not execute code or accept arbitrary regular
expressions. This avoids turning configuration into executable input and avoids
unbounded regex behavior.

A line-comment definition uses its `value` as the marker. The comment marker
is therefore selected by configuration rather than hard-coded in the engine.
The initial token set leaves comments disabled until the language design picks
the source comment syntax.

## Matching rules

At each source offset, every configured matcher is considered. The longest
match wins; priority resolves equal-length matches. An unresolved equal-length,
equal-priority collision is a lexical error. Whitespace and other non-emitted
definitions still advance source positions.

Strings currently use JSON string escaping. This is an initial lexical
implementation detail, not a decision that Spike source strings must
permanently use JSON escape semantics.

## Bootstrap implementation boundary

The executable reference implementation is under `tools/lexer/` and uses only
the Python standard library so the JSON contract can be exercised without
coupling the VM's Ada/SPARK packages to a parser dependency. The parser-facing
token record is deliberately stable and language-neutral. A production Ada
implementation can consume the same versioned contract later.
