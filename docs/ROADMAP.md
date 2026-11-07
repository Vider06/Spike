# Spike 0.1 roadmap

**Status:** Ordered implementation plan

## Phase 0 — Architecture foundation

Completed through the initial language specification and architecture baseline. The project identity, custom syntax direction, virtual-ISA model, and x86-family target direction are established.

## Phase 1 — Normative executable core

Define the first executable instruction subset and the machine-state contract.

Deliverables:
- Sixteen 64-bit general-purpose virtual registers, a 64-bit instruction-index PC, four explicit status flags, and execution state.
- Deterministic reset state and instruction-step contract.
- Normative semantics for MOV, ADD, SUB, AND, OR, XOR, NOT, and HALT.
- Positive, negative, boundary, aliasing, and state-transition test vectors.
- Explicit exclusion of memory, stack, calls, branches, and host services from this first subset.

**Exit:** every instruction in the subset has complete operands, state effects, flag behavior, and test vectors.

## Phase 2 — Virtual machine state implementation

Implement the machine-state types and invariant-preserving operations in Ada 2022, using SPARK for the bounded deterministic core.

Deliverables:
- Register and flag types.
- Machine state and execution-state types.
- Deterministic initialization.
- Checked register-index access.
- Contracts and unit tests for state invariants.

**Exit:** the machine-state package compiles, its tests pass, and GNATprove results are recorded for the units actually in SPARK.

## Phase 3 — Frontend and Quick Engine

Implement lexer, parser, semantic validation, validated instruction records, and the Quick interpreter.

**Exit:** the semantic vectors pass in Quick mode; malformed source produces diagnostics rather than uncontrolled termination.

## Phase 4 — Memory and control-flow extensions

Specify and implement memory regions, loads/stores, faults, branches, stack behavior, and calls in dependency order. Each feature requires normative semantics and tests before implementation.

## Phase 5 — x86-64 backend

Lower the validated virtual instructions to x86-64 while preserving virtual state and flag semantics. Add encoding tests, branch fixups, and differential tests.

**Exit:** every claimed native instruction has independent encoding evidence and Quick/Native parity tests.

## Phase 6 — Object output and hosted execution

Add ELF64 relocatable output for the declared hosted Linux x86-64 profile, symbols, relocations, and external linker integration.

## Phase 7 — Conformance and 0.1 stabilization

Deliver conformance fixtures, differential/property tests, fuzzing, scoped SPARK proof reports, examples, user documentation, and an accurate feature matrix.

## Deferred

Additional native architectures, PE/COFF, Mach-O, a custom linker, vector/floating-point operations, atomics, concurrency, privileged kernel/bootloader profiles, macros, self-hosting, and optimizations beyond correctness-preserving lowering.

## Change control

If implementation exposes a flaw in a normative decision, update the ADR and specification before relying on changed behavior. Implementation convenience must never silently become language semantics.
