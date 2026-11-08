# Spike 0.1 memory and machine-state model

**Status:** Bounded byte-memory safety layer implemented; stack and multi-byte operations remain deferred.

## Machine state

The architectural register state is defined by [ISA 0.1](../isa/ISA-0.1.md) and [ADR 0009](adr/0009-initial-executable-subset.md): sixteen 64-bit GPRs, instruction-index PC, Z/N/C/V flags, and RUNNING/HALTED/FAULTED execution state.

## Bounded virtual memory

The VM memory package is generic over a finite byte capacity and a finite number of mapped regions. A memory instance owns its storage; it does not expose host pointers or permit callers to index its backing array directly.

A region has a half-open address interval [start, start + length) and explicit read, write, and execute permissions. Mapping rejects zero-length regions, out-of-capacity ranges, overlapping regions, and write-plus-execute permissions. The range check validates the start first and then checks length against capacity minus start, avoiding overflow during validation.

All reads, writes, and instruction-fetch byte accesses validate the address, require a mapped region, and check the corresponding permission. Failed writes leave storage unchanged. Failed reads return a zero output value and a failure result. Instruction fetch requires execute permission; ordinary reads do not imply execute permission.

The initial implementation uses a bounded byte array. It deliberately does not expose host addresses, unchecked conversions, or raw storage references.

## Security invariants

- Memory capacity and region-table capacity are fixed at instantiation.
- Mapped regions are in-bounds and pairwise non-overlapping.
- Write-and-execute mappings are rejected (W^X).
- Every access checks bounds, mapping, and permission before touching storage.
- Memory operations return explicit result values rather than relying on host faults or exceptions for expected invalid accesses.
- Byte access is independent of host endianness; multi-byte accessors must define byte order and atomic failure behavior before being added.

## Deferred

A virtual stack, stack pointer, load/store widths, multi-byte atomic accesses, dynamic allocation, paging, concurrency, and system services remain deferred. Each requires explicit architectural semantics and dedicated boundary/fault tests before implementation.
