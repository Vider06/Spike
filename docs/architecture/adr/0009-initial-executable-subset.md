# ADR 0009: Initial executable subset and machine-state contract

**Status:** Accepted

## Context

The architecture baseline intentionally left the exact VM state and instruction semantics open. Implementation cannot safely begin while register layout, PC meaning, flag behavior, and the first instruction subset remain ambiguous.

The first implementation should be small enough for deterministic unit tests and meaningful SPARK contracts. Memory, stack, branches, and host interfaces introduce additional models and are not prerequisites for proving the basic register machine.

## Decision

The first executable machine has:

- Sixteen independent unsigned 64-bit general-purpose registers, R0-R15.
- A 64-bit PC measured in validated instruction entries.
- Four explicit flags: Z (zero), N (most-significant result bit), C (carry for addition / borrow for subtraction), and V (signed overflow).
- Three execution states: RUNNING, HALTED, and FAULTED.
- A deterministic reset state with zeroed registers, PC, and flags, and execution state RUNNING.

The initial instruction subset is MOV, ADD, SUB, AND, OR, XOR, NOT, and HALT. Arithmetic/logical destination operands may alias their source operands. Source values are read before any destination update.

ADD and SUB produce modulo-2^64 results. ADD sets C on unsigned carry-out; SUB sets C on unsigned borrow. Both set V according to signed two's-complement overflow. Both update Z and N from the result. Logical operations update Z and N and clear C and V. MOV and NOT preserve flags. HALT changes only execution state.

The PC identifies the next instruction to execute. A step fetches at the current PC and advances it to the following instruction before the instruction's semantic effects are committed. HALT therefore leaves PC pointing after the HALT instruction.

The machine-state package is implemented in Ada 2022. Bounded deterministic logic should use SPARK where practical; formal verification claims must identify the exact units, contracts, assumptions, and GNATprove results.

## Alternatives considered

- Host-register-shaped state: rejected because it couples virtual semantics to one backend.
- Byte-address PC in the initial interpreter: deferred; the initial validated instruction sequence is indexed by instruction entries.
- Implicit host flags: rejected because host flag behavior is not the language contract.
- Adding memory and stack immediately: deferred to keep the first state model bounded.
- Starting with a larger ISA: rejected until the smallest executable subset is tested end to end.

## Consequences

The first VM state is independent of x86-64 register allocation and host ABI. The Quick Engine can be tested without a source parser by executing validated instruction records. The Native backend must later reproduce the same virtual flags and register effects.

No memory, stack pointer, branch, call/return, or system-service behavior is implied by this ADR.

## Follow-up

Implement the machine-state types, deterministic initialization, checked register access, and invariant tests. Then implement the instruction semantics and Quick step loop against the normative ISA document.
