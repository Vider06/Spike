# Spike 0.1 memory and machine-state model

**Status:** Proposed; requires normative decisions

## Address model

The proposal uses 64-bit virtual address values, not an assumption that every possible address is mapped. Distinguish virtual addresses, mapped regions, host addresses, and symbolic addresses resolved by assembler/linker.

## Candidate regions

| Region | Purpose | Proposed permissions |
|---|---|---|
| Code | Instructions | Read and execute |
| Read-only data | Constants | Read |
| Data | Initialized objects | Read and write |
| BSS | Zero-initialized storage | Read and write |
| Stack | Explicit virtual stack | Read and write, bounded |

Exact layout and initial SP remain open. Virtual and native process stacks are separate concepts.

## Endianness and access semantics

Little-endian is proposed for the first x86-64 profile. Every load/store defines width, address calculation, alignment, sign/zero extension, permissions, region-crossing behavior, and faults.

## Arithmetic

Fixed-width modulo arithmetic is a candidate for integer result values, with carry and signed overflow represented independently. Division by zero and signed minimum divided by negative one need explicit rules; host CPU exceptions must not accidentally define Spike behavior.

## Faults

Candidate faults include invalid opcode/operand, unmapped access, permission violation, misalignment if enforced, division fault, and invalid control-flow target. Specify whether faults terminate execution, return structured status, or can be caught. Catchable exceptions are deferred unless required.

Native mode may use OS mappings and host faults internally. Those mechanisms are not the Spike contract.

## Deferred

Dynamic allocation, paging, memory mapping instructions, segmentation, shared memory, atomics, and concurrency.
