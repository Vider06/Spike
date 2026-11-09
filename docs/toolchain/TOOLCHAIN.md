# Spike toolchain architecture

## Pipeline

```text
Source
  -> Frontend/Lexer
  -> Typed token list
  -> Frontend/Parser
  -> Name and type validation
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

The frontend IR is the only program representation shared by both backends. It preserves source locations, typed operands, labels, selected profile, and instruction effects. It contains no host register allocation or target byte encoding.

## Component ownership

| Area | Responsibility | Current status |
|---|---|---|
| `frontend/lexer` | SPARK lexical rules, typed tokens, source spans, structured diagnostics | Phase 1 implementation |
| `frontend/parser` | Grammar and structured syntax tree | Planned |
| `frontend/ir` | Validated target-independent instructions | Planned |
| `backend/quick/interpreter` | Execute validated IR | Planned |
| `backend/quick/vm` | Registers, memory, stack, virtual semantics | VM primitives implemented |
| `backend/build/assembler` | Resolve assembly constructs and labels | Planned |
| `backend/build/encoder` | Emit target instruction bytes | Planned |
| `backend/build/object` | Sections, symbols, relocations, object metadata | Planned |
| `backend/build/linker` | Final link orchestration | Planned |
| `leng` | Machine-readable language tables and schemas | Reserved for the Phase 2 verb table |

## Language data boundary

The lexer does not load JSON and does not contain a JSON-defined vocabulary. Its output vocabulary is deliberately small: word, quoted text, left/right bracket, comma, flag, newline with indentation, and comment.

Phase 2 introduces the verb-definition JSON. Its file loader and JSON parser remain ordinary Ada, outside SPARK. A validator checks the complete document and emits a normal Ada table. From that validated table onward, parser and semantic-core code use SPARK-compatible types and contracts. The manifest in `src/leng/language.json` remains the index for future language tables.

## Ada and SPARK

Ada 2022 is the implementation language. Bounded deterministic state transitions, range checks, predicates, and invariants should use SPARK when they can be expressed with tractable contracts. JSON parsing, filesystem/process integration, and dynamic dispatch may remain ordinary Ada. Do not claim whole-toolchain formal verification merely because some units use SPARK; always report the exact proof boundary and results.

## Error handling

Every phase uses one diagnostic record: phase, stable code, zero-based byte offset, and one-based line/column. Human-readable formatting is a separate presentation step. Expected user errors are returned as structured diagnostics, not uncontrolled crashes.

## Reproducibility

Every positive/negative lexer rule has explicit tests, and the basic source fixture has a checked-in golden token listing. Later phases add golden syntax-tree, IR, and execution-result files for each program fixture. Compiler versions, target profile, object format version, and relevant build options should be recorded when they become applicable.
