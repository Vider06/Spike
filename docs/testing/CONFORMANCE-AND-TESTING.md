# Spike conformance and testing strategy

## Objectives

Establish parser correctness, validation rules, Quick semantics, Native lowering parity, correct x86-64 encoding, correct object metadata, and explicit rejection of unsupported features.

## Test layers

- Lexer/parser: valid and invalid fixtures for literals, comments, labels, directives, operands, and source spans.
- ISA semantics: normal and boundary values, aliasing, flags, overflow, and fault cases for every instruction.
- Native encoding: exact byte tests validated with independent assembler/disassembler tools and architecture manuals.
- ELF: headers, section types and flags, symbols, relocations, undefined symbols, and out-of-range fixups.
- End-to-end: equivalent Quick and Native programs under a declared target profile.

## Differential testing

Each case includes source, profile, initial virtual state, expected result/fault, Quick result, and Native result. Compare defined virtual registers, flags, memory, output, and halt/fault class. Do not compare host addresses or timing.

## Property-based testing

Generate valid instruction sequences. Candidate properties: MOV preserves its source; an instruction changes only declared state; store followed by load at the same valid address and width returns the stored value; documented stack operations restore specified state; branches follow defined conditions. Derive properties from the ISA specification, not assumptions from familiar assembly.

## Fuzzing

Fuzz lexer, parser, validator, object writer, and Quick Engine. Malformed input must yield diagnostics or structured faults, not memory corruption or uncontrolled termination. Keep malformed-source and valid-instruction generators separate.

## SPARK proofs

Use GNATprove for bounded core units where contracts permit: numeric parsing, register-index validation, bounded decoding, symbol-table invariants, and address calculations. Report exactly what is proved and what remains trusted. Proof does not replace differential tests or independent object validation.

## Feature gate

A feature is complete only with normative semantics, positive and negative syntax tests, Quick tests, Native tests when claimed, differential tests where both paths exist, unsupported-case diagnostics, and documentation.
