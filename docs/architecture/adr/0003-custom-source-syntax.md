# ADR 0003: Custom Spike source syntax

**Status:** Accepted direction

## Context

Spike should be more readable than traditional assembly while preserving explicit low-level operations and avoiding hidden high-level behavior.

## Decision

Define a first-party grammar. Instructions, operands, memory accesses, labels, directives, and pseudo-instructions must be visually and semantically unambiguous. Syntax does not inherit x86 behavior merely because a mnemonic looks familiar.

## Alternatives

- NASM-like syntax: familiar, but risks inheriting x86 conventions.
- C-like syntax: readable, but encourages implicit evaluation and abstraction.
- Positional opcode notation: compact but less approachable.

## Consequences

A normative grammar and parser conformance suite are required. Widths, symbols, expressions, and directives need consistent rules. Syntax can evolve before 0.1 stabilization; afterward, compatibility requires review.

## Follow-up

Decide case sensitivity, comment syntax, operand count conventions, width notation, symbol scope, and expression precedence.
