# Spike 0.1 memory and machine-state model

**Status:** Bounded byte memory, atomic little-endian word access, and a memory-backed bounded stack are implemented; formal verification remains in progress.

## Machine state

The architectural register state is defined by [ISA 0.1](../isa/ISA-0.1.md), [ADR 0009](adr/0009-initial-executable-subset.md), and [ADR 0010](adr/0010-memory-stack-and-control-flow.md): sixteen 64-bit GPRs, instruction-index PC, byte-address SP, Z/N/C/V flags, and RUNNING/HALTED/FAULTED execution state.

## Bounded virtual memory

The VM memory package is generic over a finite byte capacity and a finite number of mapped regions. A memory instance owns its storage; it does not expose host pointers or permit callers to index its backing array directly.

A region has a half-open address interval [start, start + length) and explicit read, write, and execute permissions. Mapping rejects zero-length regions, out-of-capacity ranges, overlapping regions, and write-plus-execute permissions. The range check validates the start first and then checks length against capacity minus start, avoiding overflow during validation.

All reads, writes, and instruction-fetch byte accesses validate the address, require a mapped region, and check the corresponding permission. Failed writes leave storage unchanged. Failed reads return a zero output value and a failure result. Instruction fetch requires execute permission; ordinary reads do not imply execute permission. Multi-byte word accesses use little-endian byte order and require the complete eight-byte range to fit inside one mapped region with the requested permission. Validation occurs before any storage mutation, so failed word writes are atomic.

The implementation uses a bounded byte array. It deliberately does not expose host addresses, unchecked conversions, or raw storage references. Word reads and writes use little-endian byte order, require the entire eight-byte range to fit inside one region, and validate permissions before reading or mutating storage.

## Security invariants

- Memory capacity and region-table capacity are fixed at instantiation.
- Mapped regions are in-bounds and pairwise non-overlapping.
- Write-and-execute mappings are rejected (W^X).
- Every access checks bounds, mapping, and permission before touching storage.
- Memory operations return explicit result values rather than relying on host faults or exceptions for expected invalid accesses.
- Byte access is independent of host endianness; multi-byte words have explicit little-endian encoding and all-or-nothing writes.
- The stack pointer is architectural machine state; stack bounds are separate, explicit, and checked on every push/pop.
- Stack operations update SP only after the corresponding memory access succeeds.
- The stack grows downward in an explicitly configured, eight-byte-aligned half-open interval.
- CALL saves the already-advanced instruction-index PC; RETURN restores it from the bounded stack.
- Branch conditions read Z/N/C/V without modifying flags.

## Deferred

Source-level LOAD/STORE forms, dynamic allocation, paging, concurrency, and system services remain deferred. Memory-operation integration with machine state and final fault propagation policy remain open VM work.
