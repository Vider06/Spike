# Language definitions

This directory is the machine-readable source of truth for structured Spike
language definitions. `language.json` is the manifest.

- `verbs/verbs.json` defines verb names, supported operand forms, allowed
  flags, and positional keywords.
- `verbs/verbs.schema.json` describes the JSON contract.
- `verbs/verb_table_types.ads` defines the bounded SPARK-compatible table
  representation.
- `verbs/verb_table_config.adb` is the Ada-only JSON loader and validator.

The Phase 1 lexer does not load JSON. It recognizes lexical shapes only.
Phase 2 validates the verb document in ordinary Ada and converts it into a
bounded table. The parser and later frontend phases consume only that
validated representation; they must not contain parallel hardcoded verb
lists.

Markdown remains the normative home for prose rules and rationale.
