# Spike 0.2 implementation roadmap

**Status:** Phase 1 implementation in progress. A phase is complete only when its stated tests and diagnostics are present and pass.

## Phase 1 — Lexer

**Output:** a bounded list of tokens, each with a kind and source position (line, column, byte offset, and source span).

Token kinds: word, quoted text, left bracket, right bracket, comma, `--flag`, newline with indentation, and comment. The lexer checks lexical shape only: quote termination, flag spelling, bracket balance and bracket-edge whitespace, comma spacing and placement, and valid source characters. It does not know verb names or operand meanings.

**Completion gate:** each lexical writing rule has a positive and a negative test; every negative case returns the shared diagnostic record with the correct line and column. A checked-in golden fixture verifies the exact token list.

## Phase 2 — Verb table (JSON)

Define the verb table schema: verb name, operand forms, flags, keywords such as `into` and `from`, and operand kinds (name, value, list, or bracketed expression). The JSON file loader and JSON parser stay outside SPARK. A validator rejects malformed entries precisely and emits a normal Ada table.

**Completion gate:** malformed JSON and malformed entries produce stable, field-specific diagnostics such as `verb cop, operand 2: unknown type`. Everything consuming the validated table uses SPARK-compatible data.

## Phase 3 — Parser

Input: tokens plus the validated verb table. Output: a printable syntax tree containing nested parts, source lines, and operands. The parser checks structure only and consults the table for each verb's operand shape. It must not contain a hardcoded list of verb names.

**Completion gate:** a representative program becomes the expected printable tree, compared against a golden file.

## Phase 4 — Names and scope

Build symbol tables for variables and parts, with `global`, `local`, and `private` visibility. Resolve `get`, `give`, and `set` aliases and scope transitions.

**Completion gate:** unresolved names, reads of non-exported variables, and aliases used outside their scope report the correct source location.

## Phase 5 — Types and checks

Determine every variable and expression type and validate that literal content is valid for its type. Add compile-time checks for `get` without `wait.oncall`, circular dependencies, lock ordering, and `wait.oncall` on infinite parts.

**Completion gate:** every rule has an invalid program that produces the expected diagnostic at the responsible source location.

## Phase 6 — IR definition

Define a small target-independent IR before implementing verb lowering. Operations use symbolic operands (variables, labels, virtual registers), not concrete addresses. Each operation records what it reads, writes, and locks, plus its original source location for explain output, tracing, and runtime diagnostics.

**Completion gate:** the IR has a stable printable form and a validator for label definitions and operand consistency.

## Phase 7 — Lowering (syntax tree to IR)

Register one lowering function per verb name in the validated verb table. The registry associates data-defined verbs with their implementation without making the parser depend on verb names.

**Completion gate:** every supported verb has a test that compares generated IR with a handwritten expected golden file.

## Phase 8 — IR to VM

Allocate virtual registers and addresses from validated IR, then emit VM instructions. Keep VM architectural semantics in the existing VM packages; this phase adds the bridge from IR to those primitives.

**Completion gate:** the same representative program runs in the interpreter and produces the expected output.

## Rules shared by every phase

- Diagnostics share one structure from Phase 1: phase, stable code, byte offset, line, and column.
- Every source fixture has a golden output for each implemented representation: tokens, syntax tree, IR, or execution result.
- The JSON loader is ordinary Ada outside SPARK. From the validated verb table onward, the core uses SPARK-compatible structures and contracts.
- The VM is not rewritten during the lexer phase. Its existing primitives remain the execution foundation for Phase 8.
- The Spike Manager is deferred until the language pipeline is in place.
