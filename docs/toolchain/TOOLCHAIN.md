# Spike toolchain architecture

## Pipeline

    Source -> Lexer -> Parser -> Syntax representation
           -> Semantic validation -> Validated virtual instructions
                |                              |
                v                              v
            Quick Engine                 x86-64 backend
                |                              |
            VM result                      Lowering
                                               |
                                         Register allocation
                                               |
                                            Encoder
                                               |
                                          ELF writer
                                               |
                                      External system linker

An internal IR is an implementation choice. It must preserve source spans, typed operands, selected profile, and instruction effects.

## Components

| Component | Responsibility |
|---|---|
| Lexer | Tokens, literals, comments, source spans |
| Parser | Grammar and syntax tree |
| Validator | Operand forms, symbols, directives, profile checks |
| ISA model | Instruction definitions and semantic effects |
| Quick Engine | Execute validated virtual instructions |
| Native backend | Lower virtual instructions to x86-64 |
| Encoder | Emit exact native instruction bytes |
| Object writer | Sections, symbols, relocations, ELF metadata |
| CLI | Commands, options, diagnostics, exit codes |

## Ada/SPARK direction

Ada/SPARK remains a proposed implementation technology, not a language requirement. Put bounded deterministic core logic in SPARK where practical; use Ada for filesystem, process, and platform integration. Do not claim whole-toolchain formal verification merely because some units use SPARK. Record proof scope, assumptions, unproved checks, and trusted dependencies.

Candidate packages include Lexer, Parser, Syntax, Validation, ISA, Machine_State, Quick, Backend.X86_64, Encoding.X86_64, Object.ELF, Diagnostics, and CLI. These are organizational suggestions, not committed APIs.

## Error handling

Distinguish source errors, unsupported target features, invariant failures, host I/O errors, and runtime VM faults. Expected user errors should produce structured diagnostics, not uncontrolled crashes.

## Reproducibility

Record compiler versions, target profile, object format version, and relevant build options. Reproducibility should be maintained where timestamps and platform metadata permit.
