# ADR 0006: Bounded memory and architectural fault model

**Status:** Accepted for the bounded byte-memory safety layer; stack and multi-byte operations deferred.

## Context

A VM must not inherit the host process's memory safety or fault behavior. Native execution will eventually run inside a host process whose invalid-address behavior is OS-dependent, while the virtual ISA needs deterministic, testable access rules.

## Decision

The first memory substrate is a finite byte array with capacity selected when the generic memory package is instantiated. It exposes no host pointers or direct backing-array access.

Memory is divided into explicitly mapped, half-open regions. Each region has independent read, write, and execute permissions. Regions must be non-empty, in bounds, and pairwise non-overlapping. A region that is both writable and executable is rejected (W^X). Read, write, and instruction-fetch operations check bounds, mapping, and their respective permission before touching storage.

The API returns explicit result values for invalid ranges, unmapped addresses, permission failures, overlaps, a full region table, and W^X violations. A failed write must not modify storage. Failed reads return a zero output byte and a failure result.

The machine state records a structured fault kind and enters a terminal FAULTED state through an explicit transition. Reset is the only operation that returns a faulted machine to RUNNING. A fault transition preserves registers, PC, and flags so the failure is observable without partial architectural mutation.

## Alternatives

- Delegate behavior to host memory and host faults: rejected because it is nondeterministic and bypasses VM permissions.
- Expose raw host pointers: rejected because it leaks host address-space assumptions and weakens bounds enforcement.
- Start with a full virtual-memory manager: deferred as unnecessary for the first bounded VM substrate.

## Consequences

The memory package is generic over finite capacity and region count. Byte operations are independent of host endianness. W^X is enforced at mapping time. This ADR does not yet define multi-byte loads/stores, alignment, a virtual stack, calls, dynamic allocation, paging, mappings, atomics, or concurrency.

## Follow-up

Before adding multi-byte operations or a stack, specify access width, byte order, alignment, overflow, region-crossing behavior, stack bounds, and atomic failure behavior. Each operation must have boundary tests and SPARK contracts where practical.
