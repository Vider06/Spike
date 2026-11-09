# Spike

Spike is a low-level, assembler-oriented language with a custom source syntax and its own virtual instruction set architecture (virtual ISA).

The central rule is that **the Spike virtual ISA defines program behavior**. Quick execution and native builds are two backends for the same validated program representation; neither host CPU nor target assembly syntax defines Spike semantics.

## Architecture

```text
Spike source
    |
    v
Frontend
    Lexer -> Typed Token List -> Parser -> Validation -> IR
                                                   |
                         +-------------------------+----------------------+
                         |                                                |
                         v                                                v
                    Backend / Quick                                 Backend / Build
                    Interpreter                                     Assembler
                         |                                                |
                        VM                                      Encoder -> Object -> Link
                         |                                                |
                    Quick result                                 Native artifact
```

- **Frontend** owns source processing and target-independent IR.
- **Backend / Quick** executes validated IR using the Spike VM.
- **Backend / Build** turns validated IR into a native artifact.
- **leng** owns machine-readable language definitions in JSON.

## Current implementation

Implemented now:

- Ada 2022 virtual-machine state, memory, stack, and virtual instruction primitives.
- SPARK-based lexer with typed tokens, source locations, and structured diagnostics.
- Deterministic lexer fuzzing, positive/negative rule tests, and golden token fixtures.
- SPARK contracts and proof harnesses for bounded VM and lexer properties.

Not yet implemented: parser, semantic frontend validation, IR, Quick interpreter loop, native assembler/build pipeline, CLI, Spike Manager, and linker integration. The initial Ada-facing `Spike_API` facade is implemented for the lexer boundary; it is not yet a user-facing command-line interface. The directory structure documents these boundaries without claiming the future components already exist.

## Language definition data

The lexical rules are implemented directly by the bounded SPARK lexer; token recognition is no longer configured by JSON. [`src/leng/language.json`](src/leng/language.json) remains the manifest for machine-readable language tables. Phase 2 will add the JSON verb table and a non-SPARK loader that validates it into an Ada table consumed by the SPARK core.

## Repository layout

```text
src/
  api/                  # implemented: stable Ada-facing toolchain facade
  frontend/
    lexer/              # implemented: SPARK lexer, typed tokens, diagnostics
    parser/              # planned parser boundary
    ir/                  # planned target-independent representation
  backend/
    quick/
      interpreter/       # planned IR execution loop
      vm/                # implemented VM primitives
        state/
        memory/
        stack/
        instructions/
    build/
      assembler/         # planned assembly/build representation
      encoder/           # planned target encodings
      object/            # planned object-file writer
      linker/            # planned linker integration
  leng/                  # language JSON manifest and future verb definitions
tests/
  api/                  # public API contract tests
  frontend/lexer/
  backend/vm/
  proofs/frontend/
  proofs/vm/
scripts/ci/
```

Ada source paths are mirrored by the test and proof areas. The GPR project file lists the actual Ada source directories explicitly.

## Project decisions

| Area | Decision |
|---|---|
| Language identity | Spike owns a virtual ISA |
| Source syntax | Custom Spike syntax |
| Initial native target | x86-64 |
| Implementation language | Ada 2022 |
| Formal-methods subset | SPARK for bounded, deterministic components where practical |
| First execution path | Quick interpreter for validated IR |
| Later execution path | Native build backend |

## Documentation

- [Language specification](specification/SPECIFICATION.md)
- [Architecture overview](docs/architecture/OVERVIEW.md)
- [Public API boundary](docs/architecture/API.md)
- [Architecture decision records](docs/architecture/adr/README.md)
- [Virtual ISA 0.1](docs/isa/ISA-0.1.md)
- [Custom syntax and grammar draft](docs/language/GRAMMAR-0.1.md)
- [Toolchain architecture](docs/toolchain/TOOLCHAIN.md)
- [Lexer](docs/toolchain/LEXER.md)
- [Conformance and testing](docs/testing/CONFORMANCE-AND-TESTING.md)
- [Continuous integration and verification gates](docs/CI.md)
- [Roadmap](docs/ROADMAP.md)

> What you write is what the machine is asked to execute.

Any directive, pseudo-instruction, or convenience form that expands into other operations must document its expansion and observable side effects.
