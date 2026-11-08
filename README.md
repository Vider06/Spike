# Spike

Spike is a low-level, assembler-oriented language with a custom source syntax and its own virtual instruction set architecture (virtual ISA).

The project has three deliberately separate layers:

1. **Spike language** — source syntax, operands, labels, directives, and instruction semantics.
2. **Spike virtual machine** — architectural state, bounded virtual memory, permissions, and virtual instruction behavior.
3. **Native backend** — a future backend that lowers the same virtual ISA to the selected native target.

## Project decisions

| Area | Decision |
|---|---|
| Language identity | Spike owns a virtual ISA |
| Source syntax | Custom Spike syntax |
| Initial target family | x86; x86-64 is the first native profile |
| Implementation language | Ada 2022 |
| Formal-methods subset | SPARK for bounded, deterministic core components where practical |
| First execution path | Quick interpreter for validated virtual instructions (future work) |
| Later execution path | Native x86-64 backend (future work) |

The virtual ISA defines program behavior. Neither x86-64 nor the host CPU defines Spike instruction semantics.

## Execution paths

- `spike run program.spike` is the planned Quick-mode interface.
- `spike build program.spike` is the planned Native-mode interface.

These commands are design targets; the toolchain is not yet implemented. This VM-only implementation does not include a source interpreter, parser, frontend, CLI, or native backend.

## VM implementation scope

The current VM work focuses on its architectural state and security substrate:

- Sixteen independent 64-bit virtual registers, PC, flags, and execution status.
- Explicit terminal fault state with a structured fault kind.
- Finite virtual memory with non-overlapping mapped regions.
- Independent read, write, and execute permissions, including W^X enforcement.
- Checked byte access and instruction-fetch access.
- Deterministic reset and tests for boundary and permission failures.

The byte-memory layer does not yet imply multi-byte loads/stores, a stack, calls, branches, or host services. Those require separate architectural decisions.

## Documentation

- [Language specification](specification/SPECIFICATION.md)
- [Architecture overview](docs/architecture/OVERVIEW.md)
- [Architecture decision records](docs/architecture/adr/README.md)
- [Virtual ISA 0.1](docs/isa/ISA-0.1.md)
- [Custom syntax and grammar draft](docs/language/GRAMMAR-0.1.md)
- [Quick and Native execution model](docs/architecture/EXECUTION-MODEL.md)
- [x86-64 backend design](docs/architecture/X86-64-BACKEND.md)
- [Memory and machine-state model](docs/architecture/MEMORY-MODEL.md)
- [ABI and system interfaces](docs/architecture/ABI-AND-SYSTEM-INTERFACES.md)
- [Toolchain architecture](docs/toolchain/TOOLCHAIN.md)
- [Conformance and testing](docs/testing/CONFORMANCE-AND-TESTING.md)
- [Roadmap](docs/ROADMAP.md)

> What you write is what the machine is asked to execute.

Any directive, pseudo-instruction, or convenience form that expands into other operations must document its expansion and observable side effects.
