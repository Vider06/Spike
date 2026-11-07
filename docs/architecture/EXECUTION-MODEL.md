# Spike execution model: Quick and Native

## Shared contract

Quick and Native are execution strategies for one virtual ISA. Given the same validated instruction sequence and initial virtual state, they must agree on all defined architectural state: GPRs, flags, PC, execution state, and later-defined memory/output effects.

## Quick mode

Quick mode is an interpreter over validated instruction records, not a source-text parser executed on every step. A step is an atomic transition of the virtual machine state. The initial instruction subset and state transitions are defined in [ISA 0.1](../isa/ISA-0.1.md).

Host CPU flags must never be the semantic source of truth.

## Native mode

Native mode will lower validated Spike instructions to x86-64. A virtual instruction may become one host instruction, a sequence, or a documented helper. If correct lowering is unavailable, Native mode rejects the feature rather than approximating it.

## Lowering contract

For each lowering, record source operands, virtual registers and flags read/written, memory effects, native clobbers, relocations, fault behavior, and parity evidence. A similar mnemonic is not sufficient evidence of semantic equivalence.

## Differential testing

Run the same program and initial virtual state in both modes. Compare defined virtual registers, flags, PC, execution state, and later-defined memory/output effects. Preserve mismatches as regression tests.
