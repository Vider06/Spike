# Spike conformance and testing strategy

## Objectives

Establish lexer and parser correctness, validation rules, Quick semantics, Native lowering parity, correct target encoding, correct object metadata, and explicit rejection of unsupported features.

## Test layers

- **Lexer:** all eight token forms, quoted-text termination and escaping, comments, CR/LF/CRLF, indentation spans, balanced brackets, bracket whitespace, comma whitespace and placement, flag spelling, source locations, buffer bounds, golden token output, and malformed-input fuzzing.
- **Verb table:** schema validation, unknown-field rejection, invalid operand kinds, and precise table-entry diagnostics.
- **Parser and validation:** valid/invalid grammar fixtures, nested parts, operands, labels, directives, typed operands, and source diagnostics.
- **Names and scope:** variable/part symbol tables, visibility, aliases, and unresolved-reference diagnostics.
- **Types and checks:** expression types, content validity, dependency cycles, lock order, and `wait.oncall` constraints.
- **IR and lowering:** exact textual IR, validated labels/operands, read/write/lock effects, source locations, and per-verb golden output.
- **VM semantics:** normal and boundary values, aliasing, flags, overflow, memory permissions, stack bounds, and fault cases for every instruction.
- **Native encoding:** exact byte tests validated with independent assembler/disassembler tools and architecture manuals.
- **End-to-end:** equivalent Quick and Native programs under a declared target profile.

## Current coverage

The Phase 1 lexer has positive and negative tests for token forms and lexical shape rules, precise diagnostic-position assertions, a checked-in golden source/output pair, and deterministic malformed-input fuzzing. The public Ada API exposes the typed token list and structured diagnostics. VM tests cover machine state, memory, instruction semantics, and stack behavior. SPARK harnesses verify the selected bounded VM and lexer-property units. The parser, verb table, symbol resolver, type checker, IR, Quick interpreter, and Build backend are not implemented yet.

## Golden fixtures

Each source fixture has an expected output file for the phase under test. Phase 1 compares source text with a golden token listing. Parser tests will add syntax-tree goldens; lowering tests will add IR goldens; interpreter tests will add expected execution results. A change to a later representation must not silently rewrite earlier goldens.

## Differential testing

Each end-to-end case should include source, profile, initial virtual state, expected result/fault, Quick result, and Native result. Compare defined virtual registers, flags, memory, output, and halt/fault class. Do not compare host addresses or timing.

## Property-based testing

Generate valid instruction sequences. Candidate properties: MOV preserves its source; an instruction changes only declared state; store followed by load at the same valid address and width returns the stored value; documented stack operations restore specified state; branches follow defined conditions. Derive properties from the ISA specification, not assumptions from familiar assembly.

## Fuzzing

Fuzz the lexer, parser, validator, object writer, and Quick interpreter as each component becomes available. The current deterministic lexer fuzz harness is regression coverage, not a substitute for long-running coverage-guided fuzzing. Malformed input must yield diagnostics or structured faults, not memory corruption or uncontrolled termination.

## SPARK proofs

Use GNATprove for bounded core units where contracts permit: token-span arithmetic, source-position helpers, numeric parsing, register-index validation, bounded decoding, symbol-table invariants, and address calculations. Report exactly what is proved and what remains trusted. Proof does not replace positive/negative tests or differential testing.

## Feature gate

A feature is complete only with normative semantics, positive and negative tests, golden outputs where applicable, backend tests when claimed, differential tests where both execution paths exist, unsupported-case diagnostics, and documentation.
