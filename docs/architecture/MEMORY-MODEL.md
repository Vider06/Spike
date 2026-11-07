# Spike 0.1 memory and machine-state model

**Status:** Memory model proposed; initial executable machine state is normative.

## Normative initial state

The initial machine state is defined by [ISA 0.1](../isa/ISA-0.1.md) and [ADR 0009](adr/0009-initial-executable-subset.md): sixteen 64-bit GPRs, instruction-index PC, Z/N/C/V flags, and RUNNING/HALTED/FAULTED execution state.

The initial executable subset has no memory instructions and no virtual stack pointer. This is intentional; neither memory layout nor stack behavior is implied by the initial register machine.

## Future memory model

The following remain proposals for a later extension:

- 64-bit virtual address values and explicitly mapped regions.
- Code, read-only data, writable data, zero-initialized data, and bounded stack regions.
- Little-endian representation for the first x86-64 profile.
- Explicit access widths, alignment, permissions, region-crossing behavior, and structured faults.

Virtual addresses and host process addresses must remain distinct. Host signals and page faults are implementation mechanisms, not the Spike architectural fault contract.

Dynamic allocation, paging, mappings, atomics, and concurrency remain deferred.
