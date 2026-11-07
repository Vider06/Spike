# Spike

Spike is a low-level, assembler-oriented language with a custom source syntax and a language-defined virtual instruction set architecture (virtual ISA).

The project separates three concepts:

1. **Spike language** — source syntax, operands, labels, directives, and explicit instruction semantics.
2. **Spike virtual machine** — the architectural state and virtual instructions defined by Spike 0.1.
3. **Native target backend** — the first backend targets x86-64 and lowers Spike virtual instructions into native machine code.

The two execution paths are intended to share one semantic definition:

- `spike run program.spike` — Quick mode, executing the virtual ISA.
- `spike build program.spike` — Native mode, producing an x86-64 artifact.

These commands describe the planned interface; they are not a claim that the toolchain is implemented yet.

## Design status

The current project direction is:

| Area | Direction |
|---|---|
| Language identity | Virtual ISA, defined by Spike |
| Initial native target | x86 family; x86-64 is the proposed 0.1 execution profile |
| Source syntax | Custom Spike syntax |
| Quick mode | Interpreter for the Spike virtual ISA |
| Native mode | Lowering and encoding to native x86-64 |
| Toolchain implementation | Ada/SPARK is the proposed direction, subject to implementation ADRs |

The architecture documents distinguish accepted project direction from proposals that still need validation. In particular, x86-64 is the concrete 64-bit profile proposed for the first native backend; legacy 16-bit and 32-bit x86 are not part of the initial scope.

## Documentation

- [Language specification](specification/SPECIFICATION.md)
- [Architecture overview](docs/architecture/OVERVIEW.md)
- [Architecture decision records](docs/architecture/adr/README.md)
- [Virtual ISA 0.1 draft](docs/isa/ISA-0.1.md)
- [Custom syntax and grammar](docs/language/GRAMMAR-0.1.md)
- [Quick and Native execution model](docs/architecture/EXECUTION-MODEL.md)
- [x86-64 backend design](docs/architecture/X86-64-BACKEND.md)
- [Memory and machine state](docs/architecture/MEMORY-MODEL.md)
- [ABI and system interfaces](docs/architecture/ABI-AND-SYSTEM-INTERFACES.md)
- [Toolchain architecture](docs/toolchain/TOOLCHAIN.md)
- [Conformance and testing](docs/testing/CONFORMANCE-AND-TESTING.md)
- [Roadmap](docs/ROADMAP.md)

## Important scope note

Spike 0.1 is a design and implementation baseline, not a promise of a complete operating-system development environment. Privileged execution, boot protocols, kernel integration, multiple native architectures, dynamic linking, and a stable external ABI require separate decisions.

## Project principle

> What you write is what the machine is asked to execute.

Any directive, pseudo-instruction, or convenience form that expands into other operations must have a documented expansion and observable side effects.
