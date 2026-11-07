# Architecture Decision Records

ADRs record decisions affecting Spike's language, virtual ISA, and toolchain. They complement the normative specification.

## Status vocabulary

- Accepted: selected project decision.
- Proposed: recommendation requiring further decision or validation.
- Deferred: postponed until a concrete requirement exists.
- Superseded: replaced by a later ADR and retained for history.

## Index

| ADR | Decision | Status |
|---|---|---|
| 0001 | Spike owns a virtual ISA | Accepted |
| 0002 | x86-64 first native profile | x86 family accepted; x86-64 profile selected for first backend |
| 0003 | Custom source syntax | Accepted |
| 0004 | Shared semantics for Quick and Native | Accepted |
| 0005 | Explicit virtual machine state | Accepted for the initial state defined by ADR 0009 |
| 0006 | Defined memory and architectural fault model | Proposed; memory instructions deferred |
| 0007 | Separate virtual ABI and host ABI | Accepted boundary; concrete virtual ABI deferred |
| 0008 | ELF object output and external linking first | Proposed |
| 0009 | Initial executable subset and machine-state contract | Accepted |

New ADRs use the next four-digit number and include context, decision, alternatives, consequences, and follow-up. Accepted decisions are changed through a superseding ADR, not silently rewritten.
