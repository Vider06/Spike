# Spike 0.1 roadmap

**Status:** Ordered implementation plan

## Phase 0 — Architecture foundation

Completed through the initial language specification and architecture baseline. The project identity, custom syntax direction, virtual-ISA model, and x86-family target direction are established.

## Phase 1 — Normative executable core

The initial register state and semantics for MOV, ADD, SUB, AND, OR, XOR, NOT, and HALT are normative in [ISA 0.1](isa/ISA-0.1.md) and [ADR 0009](architecture/adr/0009-initial-executable-subset.md).

## Phase 2 — VM state and safety substrate

Implemented in the VM-only work branch:

- Sixteen virtual registers, PC, SP, flags, execution status, and structured terminal fault state.
- Deterministic initialization and reset.
- Finite virtual byte memory with an explicitly bounded region table.
- Non-overlapping mapped regions with read, write, and execute permissions.
- W^X enforcement and checked byte reads, writes, and instruction fetches.
- Checked little-endian 64-bit reads/writes with whole-range validation and atomic failure.
- A bounded memory-backed stack with overflow/underflow checks and permission enforcement.
- Tests for region boundaries, overlap, unmapped addresses, permission failures, stack bounds, and fault-state invariants.

The code and proof status still require compiler and GNATprove execution before this phase can be declared verified.

## Phase 3 — VM semantic operations

The VM operation package implements MOV, ADD, SUB, AND, OR, XOR, NOT, flag-driven conditional branches, unconditional branches, and HALT directly against machine state. It does not parse source, decode instruction bytes, or run a program loop.

Remaining work in this phase is verification: compile the packages, execute the test mains, run GNATprove, and address any diagnostics.

## Phase 4 — Frontend and Quick Engine (not part of the current VM-only work)

Implement lexer, parser, semantic validation, validated instruction records, and the Quick interpreter only in a later, separately scoped change.

## Phase 5 — Memory and control-flow extensions

Multi-byte word access, stack behavior, and flag-driven branch primitives are implemented. The remaining VM work is call/return integration, instruction-address semantics, and any additional primitive required by the interpreter-host contract. Each feature requires normative semantics and tests before implementation.

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
