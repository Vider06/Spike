# Verb table phase 2

## Data flow

`verbs.json` is parsed by the Ada-only `Verb_Table_Config` package. The
validator rejects malformed fields, unsupported operand types, duplicate
names, invalid keyword positions, and capacity overflows. It returns a bounded
`Verb_Table` value defined by `Verb_Table_Types`, which is SPARK-compatible.

Parser code receives the validated table through `Spike_API`. It must not
know concrete verb names such as `mov`, `add`, `get`, or `give`; it matches
source words against the table and checks the selected form.

## JSON contract

The root contains `schema_version` (exactly `1.0`) and a non-empty
`verbs` array. Each verb has a `name` and one or more `forms`. Each form
has an ordered `operands` array and optional `flags` and `keywords` arrays.

Operand types are `name`, `value`, `list`, and `bracket_expression`.
A keyword or separator has a name and `after_operand`, which identifies the
operand-shape group after which it appears. An operand group may declare
`repeat: true`, allowing an arbitrary comma-separated number of actual
operands. The starter `get` form uses repeated destination and source groups,
with `from` and `=` separating them.

## Limits

The validated metadata representation is bounded: 128 verb declarations, 8
forms per verb, and 8 operand-shape groups, flag declarations, or separators
per form. These are limits on metadata shape declarations, not on actual
operand cardinality. A repeated group can contain as many operands as the
source input/resource limits permit. The AST likewise has no per-statement
operand or flag count cap.

## Diagnostics

Validation errors identify the failing object and field. For example:

```text
verb cop, operand 2: unknown type 'register'
```

Malformed JSON reports the parser's location information. Unknown object
fields are rejected rather than silently ignored.
