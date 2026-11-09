# Parser

The parser consumes positioned tokens from the Phase 1 SPARK lexer and a
validated `Verb_Table` from `src/leng/verbs/`.

The JSON parser and validator are ordinary Ada code outside SPARK. They
convert `verbs.json` into the bounded, SPARK-compatible
`Verb_Table_Types.Verb_Table` representation. The parser receives this table
through the public API and does not parse JSON itself.

Each verb can declare multiple forms. A form describes ordered operand
shape groups (`name`, `value`, `list`, or `bracket_expression`), allowed
flags, and positional keywords/separators such as `into`, `from`, and `=`.
A group may declare `repeat: true`; the parser then accepts a variable-length
comma-separated sequence. The metadata group count is not a limit on the
number of actual operands in a statement.

The AST stores operand and flag spans in shared flat arrays. Statements point
to a range in those arrays, so there is no per-statement eight-item limit.
The only remaining bounds are global input/resource limits and the maximum
number of metadata shape declarations per form. The parser evaluates every
declared form and reports ambiguity rather than silently selecting the first
match. Semantic meaning belongs to later phases.
