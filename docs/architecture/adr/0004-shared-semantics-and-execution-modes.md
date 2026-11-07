# ADR 0004: Shared semantics for Quick and Native

**Status:** Proposed

## Context

Quick mode interprets Spike instructions; Native mode emits machine code. Independent semantic implementations would drift.

## Decision

Define each virtual instruction once. Quick mode interprets the semantic model. Native mode lowers it to x86-64 sequences preserving the same observable effects. Definitions include operands read and written, flags, memory effects, control flow, and possible architectural faults.

A lowering may use multiple instructions or a helper. If Native mode cannot implement an instruction correctly, it must reject it rather than approximate it.

## Alternatives

Separate duplicated implementations; treating x86 as the semantic authority; or requiring one-to-one native instruction mapping.

## Consequences

The ISA model is the source of truth. Differential testing is required. Some features may initially be Quick-only. Native output may need prologues, helpers, and state materialization.

## Follow-up

Create per-instruction semantic records and test vectors. Track lowering clobbers and fault behavior.
