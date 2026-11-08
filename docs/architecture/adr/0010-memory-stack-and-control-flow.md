# ADR 0010: Bounded memory, stack, and control-flow semantics

**Status:** Accepted

## Context

The first machine-state and arithmetic subset is not sufficient as a stable host for a future interpreter. The VM also needs bounded data access, a protected stack, conditional control flow, and a defined call/return convention. These facilities must remain independent of source syntax, instruction encoding, and host pointers.

The VM execution contract already defines PC as an instruction index and advances it to the next instruction before applying instruction semantics. CALL must follow that rule rather than inventing a byte-address return convention.

## Decision

### Memory

- Virtual memory remains a finite byte array with a finite, explicit region table.
- Regions are half-open intervals, non-overlapping, and carry independent read/write/execute permissions.
- W^X is mandatory: a region cannot be writable and executable at the same time.
- Word access is exactly 64 bits and little-endian.
- A word read or write must fit wholly within one mapped region and have the required permission.
- The complete range is checked before a word write begins. Failure does not partially modify storage.
- Instruction fetch continues to require execute permission; data reads do not imply execute permission.

### Stack

- SP is an architectural unsigned 64-bit byte address.
- A stack is separately configured with a half-open interval [lower, upper).
- Both bounds are eight-byte aligned and the interval contains at least one word.
- The stack grows downward. Configuration initializes SP to upper, the exclusive upper bound.
- PUSH computes SP - 8, writes one complete little-endian word, then commits SP.
- POP reads the word at SP, then advances SP by eight.
- Bounds, alignment, mapping, and permissions are checked before state is committed.
- Failed memory operations leave SP unchanged and return an explicit stack/memory result.

### Branches

- Branch conditions are evaluated from Z, N, C, and V.
- Supported conditions are unconditional, zero set/clear, negative set/clear, carry set/clear, and overflow set/clear.
- A taken branch sets PC to its target instruction index; an untaken branch preserves PC.
- Branches preserve all flags.

### CALL and RETURN

- Because PC is advanced before semantic execution, CALL pushes the current PC value as the return instruction index.
- CALL sets PC to its target only after the return address is successfully pushed.
- RETURN pops the saved instruction index and sets PC to that value only after the read succeeds.
- Failed stack operations do not partially update PC or SP.

## Alternatives considered

- Host pointers or host stack frames: rejected because they expose host process state and make behavior backend-dependent.
- An unbounded stack: rejected because it cannot provide deterministic memory bounds or meaningful proof obligations.
- Byte-address return addresses: rejected because the virtual PC indexes validated instruction entries.
- Partial multi-byte writes: rejected because a failed word store must not corrupt neighboring bytes.
- Implicit permission inheritance: rejected; every access explicitly requests read, write, or execute permission.

## Consequences

The VM now provides a bounded memory substrate, a stack pointer and stack abstraction, conditional branch operations, and stack-backed call/return primitives. These are VM APIs, not source-level syntax or encoded instructions.

The future interpreter must translate validated operations into these APIs and convert explicit memory/stack failures into the machine's terminal fault model. No parser, decoder, instruction-step loop, or native backend is introduced by this decision.

## Follow-up

Add concrete generic-instance tests, include them in GNATprove analysis, and require compiler warnings, run-time checks, memory-boundary tests, stack-boundary tests, and formal proof results before declaring the VM host contract ready.
