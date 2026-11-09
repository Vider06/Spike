# Language definitions

This directory is reserved for machine-readable language tables and their schemas. `language.json` is the manifest.

The Phase 1 lexer does not load JSON. Lexical token forms and their source positions are defined by the SPARK lexer in `src/frontend/lexer/`.

Phase 2 will add the verb-definition JSON and its schema. The JSON loader/parser will remain outside SPARK; a validator will convert the document into a normal Ada table suitable for the SPARK parser and semantic core. Future structured definitions can be added as separate domain files and registered in the manifest. Markdown remains the normative home for prose rules and rationale.
