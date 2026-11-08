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

**Exit:** every instruction in the subset has complete operands, state effects, flag behavior, and test vectors.

## Phase 2 — VM state and safety substrate

Implement the machine-state types and invariant-preserving operations in Ada 2022, using SPARK for bounded deterministic logic.

Deliverables:
- Sixteen virtual registers, PC, flags, execution status, and structured terminal fault state.
- Deterministic initialization and reset.
- Finite virtual byte memory with an explicitly bounded region table.
- Non-overlapping mapped regions with read, write, and execute permissions.
- W^X enforcement and checked byte reads, writes, and instruction fetches.
- Tests for region boundaries, overlap, unmapped addresses, permission failures, and fault-state invariants.

**Exit:** state and memory packages compile; unit tests pass; GNATprove results document exactly which contracts and checks are proved.

## Phase 3 — VM semantic operations

Implement the virtual instruction semantics and atomic state transitions. Keep these independent of source parsing and host execution.

**Exit:** the normative instruction vectors pass without a parser, interpreter loop, or native backend.

## Phase 4 — Frontend and Quick Engine (not part of the current VM-only work)

Implement lexer, parser, semantic validation, validated instruction records, and the Quick interpreter only in a later, separately scoped change.

## Phase 5 — Memory and control-flow extensions

Specify and implement multi-byte loads/stores, stack behavior, branches, and calls in dependency order. Each feature requires normative semantics and tests before implementation.

## Phase 6 — x86-64 backend

Lower validated virtual instructions to x86-64 while preserving virtual state and flag semantics. Add encoding tests, branch fixups, and differential tests.

## Phase 7 — Object output and hosted execution

Add ELF64 relocatable output for the declared hosted Linux x86-64 profile, symbols, relocations, and external linker integration.

## Phase 8 — Conformance and 0.1 stabilization

Deliver conformance fixtures, differential/property tests, fuzzing, scoped SPARK proof reports, examples, user documentation, and an accurate feature matrix.

## Deferred

Additional native architectures, PE/COFF, Mach-O, a custom linker, vector/floating-point operations, atomics, concurrency, privileged kernel/bootloader profiles, macros, self-hosting, and optimizations beyond correctness-preserving lowering.

## Change control

If implementation exposes a flaw in a normative decision, update the ADR and specification before relying on changed behavior. Implementation convenience must never silently become language semantics.
