# ADR 0008: ELF object output and external linking first

**Status:** Proposed

## Context

The first native backend is expected to target x86-64. A full custom linker would expand scope before core semantics are stable.

## Decision

For a hosted Linux x86-64 profile, prefer ELF64 relocatable objects and an external compatible linker. Raw binary may be a separate freestanding output mode, not a replacement for correct object output. Do not implement a general-purpose linker in 0.1 without a demonstrated need.

ELF section permissions and types must be correct: executable code, writable data, and NOBITS storage where appropriate. Avoid RWX sections by default. Relocations must match the actual instruction field and ABI.

## Alternatives

Implement a full linker; emit only flat binaries; or generate final executables without object files.

## Consequences

The assembler needs symbols, sections, alignment, and relocation support. External linker availability becomes an environment dependency. PE/COFF and Mach-O remain deferred.

## Follow-up

Confirm host OS, ELF ABI, relocation subset, linker discovery, and freestanding requirements.
