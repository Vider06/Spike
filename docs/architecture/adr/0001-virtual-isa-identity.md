# ADR 0001: Spike owns a virtual ISA

**Status:** Accepted direction

## Context

Spike must remain low-level without becoming a thin alias layer over x86 assembly. The selected project identity is virtual, with x86 as the first target family and custom syntax.

## Decision

Spike defines its own virtual ISA and architectural state. Source programs target that ISA. The first native backend lowers it to x86-64 machine code.

The virtual ISA owns instruction semantics, register behavior, arithmetic, flags, memory operations, control flow, and architectural faults. The backend owns native instruction selection, encoding, relocation, and host integration.

## Alternatives

- Direct x86 assembler dialect: simpler initially, but binds language semantics to x86.
- High-level target-neutral IR: risks hiding machine costs and low-level behavior.
- Multiple native ISAs from day one: excessive initial scope.

## Consequences

Some virtual instructions require multiple native instructions or helper sequences. Future backends can be added without changing source semantics if they implement the same ISA. Native code size and performance may differ from hand-written assembly.

## Follow-up

Specify virtual state and instruction effects. Keep target-specific extensions separate from the architecture-neutral core.
