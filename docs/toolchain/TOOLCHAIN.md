# Spike toolchain architecture

## Pipeline

```text
Source
  -> Frontend/Lexer
  -> Token Stream
  -> Frontend/Parser
  -> Semantic validation
  -> Frontend IR
       |                              |
       v                              v
  Backend/Quick                  Backend/Build
  Interpreter                   Assembler
       |                              |
      VM                         Target encoder
       |                              |
  Quick result                 Object writer
                                      |
                                  Linker
                                      |
                                Native artifact
```

The frontend IR is the only program representation shared by both backends. It preserves source spans, typed operands, labels, selected profile, and instruction effects. It contains no host register allocation or target byte encoding.

## Component ownership

| Area | Responsibility | Current status |
|---|---|---|
| `frontend/lexer` | JSON-configured tokens, source spans, token stream | Implemented |
| `frontend/parser` | Grammar and structured syntax | Planned |
| `frontend/ir` | Validated target-independent instructions | Planned |
| `backend/quick/interpreter` | Execute validated IR | Planned |
| `backend/quick/vm` | Registers, memory, stack, virtual semantics | VM primitives implemented |
| `backend/build/assembler` | Resolve assembly constructs and labels | Planned |
| `backend/build/encoder` | Emit target instruction bytes | Planned |
| `backend/build/object` | Sections, symbols, relocations, object metadata | Planned |
| `backend/build/linker` | Final link orchestration | Planned |
| `leng` | Machine-readable language and token definitions | Manifest and lexer definitions implemented |

## Language data

Machine-readable definitions belong under `src/leng/`. The root `language.json` manifest indexes domain files and schemas. The Ada lexer loads the token table; it must not contain parallel hardcoded keyword or operator spelling tables. New matcher algorithms are implemented in the engine and declared in the schema, while ordinary token additions remain JSON-only.

Normative prose, rationale, and architectural decisions remain in the specification and ADR documents. JSON should represent structured data, not duplicate prose contracts.

## Ada and SPARK

Ada 2022 is the implementation language. Bounded deterministic state transitions, range checks, predicates, and invariants should use SPARK when they can be expressed with tractable contracts. JSON parsing, filesystem/process integration, and dynamic dispatch may remain ordinary Ada. Do not claim whole-toolchain formal verification merely because some units use SPARK; always report the exact proof boundary and results.

## Error handling

Distinguish source errors, unsupported target features, invariant failures, host I/O errors, and runtime VM faults. Expected user errors should produce structured diagnostics, not uncontrolled crashes.

## Reproducibility

Record compiler versions, target profile, object format version, and relevant build options. Reproducibility should be maintained where timestamps and platform metadata permit.
