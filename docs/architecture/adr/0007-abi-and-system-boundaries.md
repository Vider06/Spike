# ADR 0007: Separate virtual ABI from host ABI

**Status:** Proposed

## Context

A virtual function convention, native host ABI, and OS syscall interface are three different contracts. System V AMD64 and Linux syscall rules must not be conflated.

## Decision

Keep separate:
1. Spike virtual calling convention for Spike-to-Spike calls.
2. Native host ABI for interoperation with host code.
3. Environment profile for OS, firmware, or monitor services.

System V AMD64 may be chosen for Linux x86-64 interoperation, but it does not automatically define Spike CALL/RET. The architecture-neutral core has no universal OS-specific SYSCALL instruction.

## Alternatives

Make System V the universal Spike ABI; bake Linux syscall registers into the core; or omit external interfaces indefinitely.

## Consequences

Adapters may be needed at host boundaries. Quick mode needs matching host-service behavior or an explicit unavailable result. Kernel and firmware profiles can define different services.

## Follow-up

Specify a minimal virtual calling convention and select the first hosted environment independently.
