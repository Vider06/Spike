# ADR 0005: Explicit virtual machine state

**Status:** Proposed

## Context

The virtual machine needs a precise state model. Directly mapping virtual SP/BP to x86-64 RSP/RBP conflates the VM with its implementation.

## Decision

Define virtual state independently of host registers. Proposed baseline: sixteen 64-bit GPRs, a 64-bit PC, separately defined status flags, a virtual stack pointer, a virtual address space, and explicit running/halted/faulted execution states.

The specification must decide whether SP is a dedicated register or an alias of a GPR. Host RSP, RIP, and RFLAGS are not writable virtual registers by implication.

## Alternatives

One-to-one host register mapping; host stack as virtual stack; or opaque state with high-level-only operations.

## Consequences

Native code generation needs register allocation and possibly spills. Helper calls must preserve live virtual state. Quick mode can implement deterministic state independent of x86 quirks.

## Follow-up

Specify names, reserved registers, reset state, PC units, flag bits, SP policy, and instruction atomicity.
