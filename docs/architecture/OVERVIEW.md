# Spike 0.1 architecture overview

## Identity and boundaries

Spike defines its own low-level virtual instruction set architecture. Source code targets the Spike virtual ISA, not x86 mnemonics. The first native backend is planned for x86-64, but x86-64 implements Spike semantics rather than defining them.

The architecture has three layers:

1. Language frontend: source syntax, operands, labels, directives, and diagnostics.
2. Virtual machine: architectural state and virtual instruction behavior.
3. Native backend: future lowering, register allocation, encoding, relocations, and host integration.

## Execution pipeline

    Spike source
        |
    Lexer and parser
        |
    Validated virtual instructions
        |                         |
    Quick interpreter        Future x86-64 backend
        |                         |
    Virtual state             Native code

The initial implementation begins with the virtual-machine state package, before the frontend or either execution engine.

## Initial executable machine

The normative initial subset uses sixteen 64-bit GPRs (R0-R15), a 64-bit instruction-index PC, Z/N/C/V flags, and RUNNING/HALTED/FAULTED execution states. The initial instruction subset is MOV, ADD, SUB, AND, OR, XOR, NOT, and HALT. See [ISA 0.1](../isa/ISA-0.1.md) and [ADR 0009](adr/0009-initial-executable-subset.md).

The first subset deliberately has no memory, stack, branch, call, or host-service instructions. This keeps the state model bounded and lets the first implementation establish precise, testable invariants.

## Implementation technology

The toolchain implementation uses Ada 2022. SPARK is used for bounded deterministic components where practical, with proof claims limited to the units and properties actually analyzed by GNATprove. Filesystem, process, and platform integration may use ordinary Ada.

The implementation language is independent of the Spike source language and does not constrain third-party implementations.

## Architectural invariants

- Every virtual instruction has one normative semantic definition.
- Quick and Native modes implement the same virtual semantics.
- Host registers and flags are implementation resources, not virtual state.
- Directives are assembly-time constructs, not VM instructions.
- Unsupported features are rejected explicitly.
- Implementation convenience must not silently become language semantics.

## Deferred

Memory, stack, calls, branches, system services, privileged profiles, additional native architectures, dynamic linking, floating-point/vector state, concurrency, macros, and self-hosting are deferred until separately specified.
