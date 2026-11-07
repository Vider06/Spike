# Spike execution model: Quick and Native

## Shared contract

Quick and Native are execution strategies for one virtual ISA. Given the same program, profile, and defined initial state, they must agree on architecturally observable registers, flags, memory, control flow, halt/fault class, and defined output interactions. Timing, native code layout, and unspecified host details are not semantic requirements.

## Quick mode

Quick mode is an interpreter over validated instruction records, not a source-text parser executed on every step. A cycle fetches the instruction at virtual PC, validates it, reads operands, computes defined-width results, applies only specified state updates, and reports structured faults.

Host CPU flags must not be the semantic source of truth.

## Native mode

Native mode lowers validated Spike instructions to x86-64. A virtual instruction may become one instruction, a sequence, a branch sequence, or a documented helper call. If correct lowering is unavailable, Native mode rejects the feature explicitly.

## Lowering contract

For each lowering record source operands, virtual registers and flags read/written, memory effects, native clobbers, relocations, fault behavior, and parity evidence. A similar mnemonic is not sufficient evidence of semantic equivalence.

Runtime helpers must document their calling convention, clobbers, memory effects, and availability. They must not introduce hidden allocation, I/O, or locking.

## Differential testing

Run the same test program and initial virtual state in both modes. Compare defined registers, flags, memory regions, output, and halt/fault class. Preserve mismatches as regression tests. Exclude host-specific details such as raw process addresses and timing.
