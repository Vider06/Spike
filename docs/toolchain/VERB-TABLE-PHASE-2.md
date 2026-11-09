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
A keyword has a name and `after_operand`, which identifies the number of
operands that appear before it. The starter `get` form places `from` after
its second operand.

## Limits

The validated representation is bounded: 128 verbs, 8 forms per verb, and 8
operands, flags, or keywords per form. The validator rejects values outside
these limits before returning the table.

## Diagnostics

Validation errors identify the failing object and field. For example:

```text
verb cop, operand 2: unknown type 'register'
```

Malformed JSON reports the parser's location information. Unknown object
fields are rejected rather than silently ignored.
