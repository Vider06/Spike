# Parser

The parser consumes positioned tokens from the Phase 1 SPARK lexer and a
validated `Verb_Table` from `src/leng/verbs/`.

The JSON parser and validator are ordinary Ada code outside SPARK. They
convert `verbs.json` into the bounded, SPARK-compatible
`Verb_Table_Types.Verb_Table` representation. The parser receives this table
through the public API and does not parse JSON itself.

Each verb can declare multiple forms. A form describes ordered operand
shapes (`name`, `value`, `list`, or `bracket_expression`), allowed flags,
and positional keywords such as `into` and `from`. The parser must perform
structural validation using this metadata and must not hardcode verb names.
Semantic meaning belongs to later phases.

The bounded representation allows 128 verbs, 8 forms per verb, and up to 8
operands, flags, and keywords per form. The Ada validator rejects overflow
before a table is returned.
