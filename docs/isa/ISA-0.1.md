# Spike Virtual ISA 0.1 — design draft

**Status:** Proposed architecture baseline; not a frozen encoding

## Purpose

This document sketches the virtual machine contract independently of x86 opcode encoding. Candidate instructions become normative only after operand forms, effects, flags, overflow, faults, and Quick/Native behavior are specified.

## Proposed machine state

| State | Candidate definition | Open decision |
|---|---|---|
| GPRs | Sixteen 64-bit integer registers R0–R15 | Reserved/special registers |
| PC | 64-bit program counter | Instruction index or byte address |
| Flags | Explicit status bits | Exact bits and write masks |
| SP | Virtual stack pointer | Dedicated state or GPR alias |
| Memory | Virtual address space | Mapping and layout |
| Execution | Running, halted, faulted | Fault taxonomy |

No virtual register aliases host RAX, RSP, RIP, or RFLAGS by default.

## Candidate instruction groups

- Data movement: MOV, LOAD, STORE.
- Integer arithmetic: ADD, SUB, MUL, DIV.
- Bitwise and shifts: AND, OR, XOR, NOT, SHL, SHR; consider SAR.
- Control flow: JMP, conditional branches, CALL, RET, HALT.
- Environment services: outside the architecture-neutral core pending a profile.

For MUL, define low-half versus full-width result. For DIV, define signedness, quotient/remainder destinations, zero-divisor behavior, and overflow behavior.

## Operand model

Candidate operands are registers, integer literals, symbols, and simple base-plus-displacement memory references. Indexed addressing, scale factors, complex expressions, and indirect branches should wait until the base model is stable.

The project must choose either a consistent two-operand or three-operand arithmetic convention. Do not mix conventions arbitrarily.

## Arithmetic and flags

A candidate ADD/SUB result model is modulo 2^64, with carry and signed overflow reported independently. This remains a proposal. Define signedness, truncation, aliasing, and flag effects per instruction.

A compact flag set might include zero, sign, carry, and signed overflow. Do not copy x86 RFLAGS wholesale. Each instruction declares which flags it writes and preserves.

## Memory

Specify transfer width, address calculation, alignment, sign/zero extension, permissions, cross-region behavior, and faults. Little-endian is proposed for the initial x86-64 profile, but byte order belongs to a declared profile.

## Pseudo-instructions

Pseudo-instructions are assembler expansions, not virtual opcodes. Document expansion, register clobbers, flag effects, memory effects, and size variability. NOP must preserve all architecturally visible state; it cannot be implemented as an ADD that changes flags. PUSH/POP wait until SP and fault atomicity are defined.

## Encoding

Spike source syntax is assembled to the selected native target. A serialized fixed-width virtual bytecode is not required for 0.1. If introduced later, it needs a separate versioned specification.

## Open questions

Register naming and SP policy; PC units; exact flags; width model; signed and unsigned division; branch conditions; CALL/RET semantics; memory layout; compare instruction; and externally visible register preservation.
