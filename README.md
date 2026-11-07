# Spike

Spike is a low-level, assembler-oriented language with a custom source syntax and its own virtual instruction set architecture (virtual ISA).

The project has three deliberately separate layers:

1. **Spike language** — source syntax, operands, labels, directives, and instruction semantics.
2. **Spike virtual machine** — the architectural state and virtual instructions defined by Spike.
3. **Native backend** — a future backend that lowers the same virtual ISA to the selected native target.

## Project decisions

| Area | Decision |
|---|---|
| Language identity | Spike owns a virtual ISA |
| Source syntax | Custom Spike syntax |
| Initial target family | x86; x86-64 is the first native profile |
| Implementation language | Ada 2022 |
| Formal-methods subset | SPARK for bounded, deterministic core components where practical |
| First execution path | Quick interpreter for validated virtual instructions |
| Later execution path | Native x86-64 backend |

The virtual ISA defines program behavior. Neither x86-64 nor the host CPU defines Spike instruction semantics.

## Execution paths

- `spike run program.spike` is the planned Quick-mode interface.
- `spike build program.spike` is the planned Native-mode interface.

These commands are design targets; the toolchain is not yet implemented.

## 0.1 implementation sequence

1. Freeze the minimal virtual-machine state and executable instruction subset.
2. Implement and verify the machine-state package in Ada/SPARK.
3. Implement the source frontend and validated instruction representation.
4. Implement the Quick interpreter against the normative semantics.
5. Add the x86-64 backend only after the shared semantics are stable.

The first executable subset is intentionally small: `MOV`, `ADD`, `SUB`, `AND`, `OR`, `XOR`, `NOT`, and `HALT`. The normative details are recorded in [ADR 0009](docs/architecture/adr/0009-initial-executable-subset.md) and [ISA 0.1](docs/isa/ISA-0.1.md).

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

## Scope boundary

The first implementation does not include memory instructions, a virtual stack, calls/returns, OS services, privileged execution, boot protocols, kernel integration, dynamic linking, or a stable external ABI. Those features require explicit specifications before implementation.

> What you write is what the machine is asked to execute.

Any directive, pseudo-instruction, or convenience form that expands into other operations must document its expansion and observable side effects.
