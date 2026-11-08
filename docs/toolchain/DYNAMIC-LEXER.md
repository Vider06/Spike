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
   match), then configured priority to break equal-length ties.
4. **Token stream** — immutable token records with kind, lexeme, decoded value,
   byte-independent Python character offsets, and one-based line/column.

## Supported matcher primitives

The initial safe matcher vocabulary is literal, identifier, decimal integer,
hex integer, binary integer, quoted string, whitespace, and line comment.
Definitions may choose token names, priorities, and whether a match is emitted.
The JSON format intentionally does not execute code or accept arbitrary regular
expressions. This avoids turning configuration into executable input and avoids
unbounded regex behavior.

The comment matcher uses a literal definition with the same token name as its
comment definition as the introducer. For example, a future configuration may
pair a comment marker literal with a line-comment rule. The initial config keeps
comments disabled until a comment marker is selected by the language design.

## Matching rules

At each source offset, every configured matcher is considered. The longest
match wins; priority resolves equal-length matches. An unresolved equal-length,
equal-priority collision is a lexical error. Whitespace and other non-emitted
definitions still advance source positions.

Strings use JSON string escaping. This is an initial lexical contract, not a
decision that Spike source strings must permanently use JSON escape semantics.

## Bootstrap implementation boundary

The current executable reference implementation is under `tools/lexer/` and
uses only the Python standard library so the JSON contract can be exercised
without coupling the VM's Ada/SPARK packages to a parser dependency. The
production Ada implementation can consume the same versioned contract later.
The parser-facing token record is deliberately stable and language-neutral.
