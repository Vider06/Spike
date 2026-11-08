# Spike Virtual ISA 0.1

**Status:** Normative virtual machine state and initial executable semantics; source-level encoding remains a later language decision.

## 1. Machine state

The initial machine state contains:

| Component | Definition |
|---|---|
| GPRs | Sixteen unsigned 64-bit registers, R0 through R15 |
| PC | Unsigned 64-bit instruction index |
| SP | Unsigned 64-bit byte address for the bounded virtual stack |
| Flags | Z (zero), N (negative/sign), C (carry/borrow), V (signed overflow) |
| Execution | RUNNING, HALTED, or FAULTED |

All GPRs, PC, SP, and flags are independent of host CPU registers and flags. There is no implicit alias to x86-64 registers.

The initial state is deterministic: all GPRs are zero, PC and SP are zero, all flags are clear, and execution is RUNNING. Configuring a stack sets SP to its exclusive upper bound.

The PC addresses entries in the validated instruction sequence, not byte offsets in source text or native machine code. The execution engine fetches the instruction at PC and advances PC to the following instruction before applying that instruction's operation. Consequently, after HALT, PC identifies the instruction following HALT.

A FAULTED state is terminal for this initial subset. Its detailed fault payload is defined by the runtime contract before faults are exposed by the Quick Engine.

## 2. Operand conventions

- Register operands are written R0 through R15.
- Integer values are 64-bit bit patterns.
- Arithmetic and logical instructions use a consistent three-operand form: destination, left source, right source.
- MOV and NOT use two operands: destination and source.
- The destination may alias either source. Both source values are read from the pre-instruction state before the destination is written.
- Immediate values are permitted where the instruction form allows them; the frontend must reject values outside the unsigned 64-bit bit-pattern range.

The source grammar and exact tokenization are specified separately in the language grammar.

## 3. Flags

- Z is set exactly when the operation's 64-bit result is zero.
- N is the most significant bit of the 64-bit result.
- C is the unsigned carry-out for ADD and the unsigned borrow-out for SUB.
- V is signed two's-complement overflow for ADD and SUB.

Instructions that do not define flag updates preserve all flags. Logical instructions update Z and N and clear C and V. MOV and NOT preserve all flags. HALT preserves all flags.

## 4. Initial instruction subset

### MOV destination, source

Copies the 64-bit source bit pattern to the destination. Flags are unchanged.

### ADD destination, left, right

Computes the unsigned 64-bit modular sum of left and right. C records carry-out; V records signed overflow; Z and N describe the truncated 64-bit result.

### SUB destination, left, right

Computes left minus right modulo 2^64. C is set when unsigned subtraction borrows; V records signed overflow; Z and N describe the result.

### AND destination, left, right

Computes bitwise AND, updates Z and N, and clears C and V.

### OR destination, left, right

Computes bitwise OR, updates Z and N, and clears C and V.

### XOR destination, left, right

Computes bitwise XOR, updates Z and N, and clears C and V.

### NOT destination, source

Computes the bitwise complement of source, writes destination, and preserves all flags.

### HALT

Changes execution state from RUNNING to HALTED. It does not modify GPRs or flags. No subsequent instruction may execute in HALTED state.

## 5. Instruction-step atomicity

Each instruction is one architectural state transition. Its defined register, flag, PC, and execution-state updates are committed together. A failed validation or execution step must not leave a partially updated architectural state.

An instruction may execute only when the machine is RUNNING. Attempting to step a HALTED or FAULTED machine is rejected by the execution API and does not mutate the state.

## 6. VM substrate operations

The following semantics are implemented as VM APIs. They do not imply a source grammar, serialized instruction encoding, decoder, or execution loop.

### Branch conditions

The VM branch primitive supports unconditional, zero-set, zero-clear, negative-set, negative-clear, carry-set, carry-clear, overflow-set, and overflow-clear conditions. A branch updates PC to the target only when its condition is true. It never changes flags.

### Bounded stack

The stack is a separately configured half-open byte interval [lower, upper). Both bounds are eight-byte aligned and the interval contains at least one word. The stack grows downward. Configuration sets SP to upper, which is the exclusive upper bound and the next free position.

PUSH computes SP - 8, writes one little-endian 64-bit word, and commits the new SP only after the complete memory write succeeds. POP reads one word at SP and increments SP by 8 only after the complete memory read succeeds. Bounds, alignment, mapping, and permissions are checked; failed accesses leave SP unchanged.

### CALL and RETURN

The VM step contract advances PC to the following instruction before applying the operation. CALL therefore pushes the current PC value (the already advanced return instruction index) and then sets PC to the target. RETURN pops that saved instruction index and restores PC. A failed stack operation leaves PC unchanged.

### Word memory access

The bounded memory API supports little-endian 64-bit word reads and writes. The full eight-byte range must fit inside one mapped region with the requested permission. The entire range is validated before a write, so a failed write cannot partially mutate memory.

## 7. Explicitly deferred

Source-level LOAD/STORE instruction forms, multiplication/division, shifts, comparisons, system calls, privileged instructions, pseudo-instructions, and instruction encodings remain deferred. They require separate architectural decisions and must not be inferred from host behavior.

## 8. Encoding independence

This document defines virtual behavior, not x86 opcode encodings and not a serialized bytecode format. Quick mode and any future Native backend must implement this contract. Native lowering may use multiple host instructions, but it may not change the observable virtual state.
