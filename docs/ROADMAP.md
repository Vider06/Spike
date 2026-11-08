# Spike implementation roadmap

**Status:** Ordered implementation plan. Component status is reflected in the repository tree and the checks that actually run.

## Phase 0 — Language and architecture foundation

The project identity, custom source syntax direction, virtual-ISA model, and x86-64 first native target are established in the [language specification](../specification/SPECIFICATION.md), [architecture overview](architecture/OVERVIEW.md), and architecture decision records.

## Phase 1 — Virtual machine foundation

Implemented VM primitives include:

- Sixteen virtual registers, PC, SP, flags, execution status, and structured terminal fault state.
- Deterministic initialization and reset.
- Finite virtual byte memory with bounded region tracking and non-overlapping mappings.
- Independent read, write, and execute permissions with W^X enforcement.
- Checked byte and little-endian word access.
- Bounded memory-backed stack with overflow/underflow checks.
- Virtual instruction semantics and explicit control-flow primitives.

The VM packages live under `src/backend/quick/vm/`.

## Phase 2 — Dynamic lexical frontend

Implemented:

- JSON-owned token definitions and schema under `src/leng/lexer/`.
- A manifest at `src/leng/language.json`.
- Ada lexer configuration validation and indexed maximal-munch matching.
- Validated token streams with bounded cursor and source-span invariants.
- Deterministic regression fuzzing and tests.
- SPARK contracts for the bounded properties that can be isolated and proved.

The lexer is under `src/frontend/lexer/`. Adding token spellings or names is data-driven; adding a new matcher primitive requires an engine/schema change.

## Phase 3 — Parser and validated IR

Next:

- Parse token streams using the language grammar.
- Produce structured diagnostics with source spans.
- Validate operands, symbols, labels, directives, and instruction forms.
- Define a stable target-independent IR consumed by both execution backends.

Boundaries are reserved under `src/frontend/parser/` and `src/frontend/ir/`.

## Phase 4 — Quick interpreter

Implement the Quick interpreter over validated IR. It should dispatch virtual instructions through the VM packages and preserve the specified VM fault model. No parsing or source syntax handling belongs in this backend.

## Phase 5 — Native Build backend

Implement the build assembler, target encoder, object writer, and linker integration under `src/backend/build/`. Add exact encoding, relocation, and object-format tests. The native backend must preserve the same virtual semantics as Quick.

## Phase 6 — Conformance and stabilization

Deliver end-to-end examples, language conformance fixtures, differential Quick/Native tests, property-based testing, long-running fuzzing where useful, scoped SPARK reports, installation instructions, and an accurate feature matrix.

## Deferred

Additional native architectures, PE/COFF, Mach-O, a custom linker, vector/floating-point operations, atomics, concurrency, privileged kernel/bootloader profiles, macros, self-hosting, and optimizations beyond correctness-preserving lowering.

## Change control

If implementation exposes a flaw in a normative decision, update the relevant ADR and specification before relying on changed behavior. Implementation convenience must never silently become language semantics.
