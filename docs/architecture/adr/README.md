# Architecture Decision Records

ADRs document decisions affecting Spike's language, virtual ISA, and toolchain. They complement, but do not replace, the normative specification.

## Status vocabulary

- Accepted direction: explicitly selected by the project owner.
- Proposed: recommended for 0.1, not yet a compatibility commitment.
- Deferred: postponed pending a concrete requirement.
- Superseded: replaced by a later ADR and retained for history.

## Index

| ADR | Decision | Status |
|---|---|---|
| 0001 | Spike owns a virtual ISA | Accepted direction |
| 0002 | x86-64 first native profile | x86 family accepted; profile proposed |
| 0003 | Custom source syntax | Accepted direction |
| 0004 | Shared semantics for Quick and Native | Proposed |
| 0005 | Explicit virtual machine state | Proposed |
| 0006 | Defined memory and fault model | Proposed |
| 0007 | Separate virtual ABI and host ABI | Proposed |
| 0008 | ELF object output and external linker first | Proposed |

New ADRs use the next four-digit number and include context, decision, alternatives, consequences, and follow-up. Accepted decisions should not be silently rewritten; use a superseding ADR.
