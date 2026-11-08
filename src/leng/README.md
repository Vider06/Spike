# Language definitions

This directory is the machine-readable source of truth for Spike language definitions. `language.json` is the manifest; it references versioned JSON modules and each module's schema.

Current modules:

- [lexer/tokens.json](lexer/tokens.json): token names, matcher primitives, priorities, and emission policy.
- [lexer/tokens.schema.json](lexer/tokens.schema.json): validation schema for lexer definitions.

As grammar, instruction-set, directives, operand forms, and ABI data become machine-readable, add separate domain files and schemas here and register them in `language.json`. Do not duplicate prose specifications in JSON: Markdown remains normative where structured data is not needed. Runtime code must load definitions from this directory rather than carry parallel hardcoded language tables.
