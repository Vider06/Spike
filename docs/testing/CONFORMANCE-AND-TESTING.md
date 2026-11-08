# Spike conformance and testing strategy

## Objectives

Establish lexer and parser correctness, validation rules, Quick semantics, Native lowering parity, correct target encoding, correct object metadata, and explicit rejection of unsupported features.

## Test layers

- **Lexer:** JSON configuration validity, maximal munch, priority rules, escaped strings, comments, ASCII boundaries, source spans, EOF, and token-stream invariants.
- **Parser and validation:** valid/invalid grammar fixtures, labels, directives, typed operands, profile restrictions, and source diagnostics.
- **VM semantics:** normal and boundary values, aliasing, flags, overflow, memory permissions, stack bounds, and fault cases for every instruction.
- **Native encoding:** exact byte tests validated with independent assembler/disassembler tools and architecture manuals.
- **Object and linking:** headers, sections, symbols, relocations, undefined symbols, and out-of-range fixups.
- **End-to-end:** equivalent Quick and Native programs under a declared target profile.

## Current coverage

Ada tests cover VM machine state, memory, instruction semantics, and stack behavior. Lexer tests exercise the JSON-driven dynamic lexer, token-stream API, and deterministic malformed-input fuzzing. SPARK harnesses verify bounded VM and lexer properties. The parser, IR, Quick interpreter, and Build backend are not implemented yet, so their test layers remain future gates rather than empty passing checks.

## Differential testing

Each end-to-end case should include source, profile, initial virtual state, expected result/fault, Quick result, and Native result. Compare defined virtual registers, flags, memory, output, and halt/fault class. Do not compare host addresses or timing.

## Property-based testing

Generate valid instruction sequences. Candidate properties: MOV preserves its source; an instruction changes only declared state; store followed by load at the same valid address and width returns the stored value; documented stack operations restore specified state; branches follow defined conditions. Derive properties from the ISA specification, not assumptions from familiar assembly.

## Fuzzing

Fuzz the lexer, parser, validator, object writer, and Quick interpreter as each component becomes available. The current deterministic lexer fuzz harness is regression coverage, not a substitute for long-running coverage-guided fuzzing. Malformed input must yield diagnostics or structured faults, not memory corruption or uncontrolled termination.

## SPARK proofs

Use GNATprove for bounded core units where contracts permit: numeric parsing, register-index validation, bounded decoding, symbol-table invariants, and address calculations. Report exactly what is proved and what remains trusted. Proof does not replace differential tests or independent object validation.

## Feature gate

A feature is complete only with normative semantics, positive and negative syntax tests, backend tests when claimed, differential tests where both execution paths exist, unsupported-case diagnostics, and documentation.
