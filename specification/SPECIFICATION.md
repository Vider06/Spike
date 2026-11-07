

---

## 22. Normative 0.1 initial executable subset

This section supersedes earlier statements in this draft that describe the initial target, machine model, syntax, execution strategy, or implementation technology as undecided. The project decisions are: Spike owns a virtual ISA; source syntax is custom; x86 is the initial target family with x86-64 as the first native profile; the toolchain implementation uses Ada 2022 with SPARK for bounded deterministic components where practical.

The initial executable virtual machine is defined by [ISA 0.1](../docs/isa/ISA-0.1.md) and [ADR 0009](../docs/architecture/adr/0009-initial-executable-subset.md). It contains sixteen independent 64-bit GPRs (R0-R15), a 64-bit instruction-index PC, Z/N/C/V flags, and RUNNING/HALTED/FAULTED execution states. Its initial instruction subset is MOV, ADD, SUB, AND, OR, XOR, NOT, and HALT.

The initial machine has no memory, stack pointer, branches, calls/returns, or host services. These are extensions, not implicit capabilities. The ISA document is normative for operand forms, arithmetic, flags, reset state, instruction atomicity, and HALT behavior.

Quick mode interprets validated virtual instructions. A future Native backend lowers the same semantics to x86-64. The host architecture and host flags do not define virtual behavior.

The exact custom source grammar remains documented as a draft until its lexical and syntactic rules are frozen. This does not block implementing the VM state and semantic engine independently of source parsing.
