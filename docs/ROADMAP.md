# Spike 0.1 roadmap

**Status:** Proposed dependency order; not a calendar commitment

## Phase 0 — Architecture baseline

Deliver project layer boundaries, ADRs, VM state draft, target profile decision, and deferred-feature list.

Exit: source targets an unambiguous virtual ISA; x86-64 profile is confirmed or revised; ISA and grammar agree.

## Phase 1 — Normative language and ISA subset

Deliver grammar, register/PC model, arithmetic and flag semantics, load/store behavior, fault model, control flow, and pseudo-instruction policy.

Exit: every MVP instruction has a complete semantic record and positive/negative test vectors.

## Phase 2 — Frontend and Quick Engine

Deliver lexer, parser, validator, machine state, interpreter, diagnostics, and structured runtime faults.

Exit: semantic vectors pass in Quick mode; fuzzing finds no known crash-class failures.

## Phase 3 — x86-64 backend

Deliver lowering rules, virtual-register preservation, flag strategy, encoder, branch fixups, and symbol handling.

Exit: all claimed instructions have encoding tests; unsupported features fail explicitly; differential tests pass.

## Phase 4 — Object output and hosted execution

Deliver ELF64 relocatable object writer for the selected hosted profile, symbols, relocations, external linker integration, and minimal host bridge.

Exit: standard tools inspect objects; a minimal program links and runs in the declared environment; ABI assumptions are documented.

## Phase 5 — Quality and 0.1 stabilization

Deliver conformance suite, differential/property tests, fuzzing, scoped SPARK proof reports, examples, user documentation, and versioned specification.

Exit: feature matrix is accurate and Quick/Native parity is demonstrated for the supported subset.

## Deferred beyond the first usable baseline

Additional architectures; PE/COFF and Mach-O; full custom linker; vector/floating-point ISA; atomics and concurrency; privileged kernel/bootloader profiles; macro system; self-hosting; optimizing passes beyond correctness-preserving lowering.

## Change control

If implementation reveals a flaw in an ADR, update the ADR and normative specification before relying on changed behavior. Implementation convenience must not silently become language semantics.
