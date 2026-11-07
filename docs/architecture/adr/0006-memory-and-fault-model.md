# ADR 0006: Defined memory and architectural fault model

**Status:** Proposed

## Context

Quick mode needs deterministic memory semantics. Native mode runs in a host process whose invalid-address behavior is OS-dependent.

## Decision

Define virtual address space, load/store widths, byte order, alignment, region permissions, and fault behavior in Spike terms. Little-endian is proposed for the first x86-64 profile. Start with code, read-only data, writable data, zero-initialized data, and a bounded stack.

Quick mode returns structured architectural faults. Native mode may use host mechanisms internally but must preserve the specified observable fault class where supported. Host signals are not themselves the language contract.

## Alternatives

Delegate all behavior to host memory; simulate an unbounded flat space; or build a complete virtual-memory subsystem immediately.

## Consequences

The initial layout and entry state must be specified. Dynamic allocation, paging, mappings, atomics, and concurrency are deferred.

## Follow-up

Specify address width, alignment, overflow, permissions, division faults, invalid branches, and fault reporting.
