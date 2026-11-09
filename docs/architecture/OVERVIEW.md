# Spike architecture overview

## Identity

Spike defines its own low-level virtual instruction set architecture. Source programs target the Spike virtual ISA, not x86 mnemonics. The first native backend is x86-64, but x86-64 implements Spike semantics rather than defining them.

## Toolchain pipeline

```text
Spike source
    |
    v
Frontend
    Lexer -> Token Stream -> Parser -> Semantic validation -> IR
                                                          |
                               +--------------------------+------------------------+
                               |                                                   |
                               v                                                   v
                         Backend / Quick                                     Backend / Build
                         Interpreter                                          Assembler
                               |                                                   |
                              VM                                          Encoder -> Object
                               |                                                   |
                         Quick result                                        Linker -> Native
```

The frontend produces target-independent validated IR. Quick and Build consume the same IR; neither backend reparses source text. This is the key separation that keeps execution behavior consistent.

## Repository mapping

- `src/frontend/lexer/`: implemented JSON-driven lexer and token stream.
- `src/frontend/parser/`: planned grammar parser.
- `src/frontend/ir/`: planned target-independent instruction representation.
- `src/backend/quick/vm/`: implemented machine state, memory, stack, and instruction primitives.
- `src/backend/quick/interpreter/`: planned IR execution loop.
- `src/backend/build/`: planned assembler, encoder, object writer, and linker integration.
- `src/leng/`: machine-readable language manifest, definitions, and schemas.

## Virtual machine

The initial machine model uses sixteen 64-bit GPRs (R0-R15), a 64-bit instruction-index PC, Z/N/C/V flags, and RUNNING/HALTED/FAULTED execution states. The virtual ISA's normative instruction semantics are documented in [ISA 0.1](../isa/ISA-0.1.md) and the accepted architecture decisions.

The VM packages are execution primitives. They do not parse source, decode a native instruction stream, or run a complete interpreter loop.

## Implementation technology

The implementation uses Ada 2022. SPARK is used for bounded deterministic components where contracts permit. Proof claims must remain limited to units and properties actually analyzed by GNATprove. Filesystem, process, JSON adaptation, and platform integration may use ordinary Ada.

## Architectural invariants

- Every virtual instruction has one normative semantic definition.
- Quick and Native modes implement the same virtual semantics.
- Host registers and flags are implementation resources, not virtual state.
- Directives are assembly-time constructs, not VM instructions.
- Unsupported features are rejected explicitly.
- Frontend code owns parsing; backends consume validated IR only.
- Implementation convenience must not silently become language semantics.
