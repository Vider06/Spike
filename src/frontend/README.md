# Frontend

The frontend owns source-language processing and target-independent representations.

1. `lexer/` contains the SPARK package `Lexer`. It produces a bounded, positioned token list and shared structured diagnostics. It recognizes lexical forms only; it does not classify words as verbs, variables, types, or keywords.
2. `parser/` consumes the token list and the validated Ada verb table produced by the Phase 2 JSON adapter. It constructs syntax trees without hardcoded verb-name lists.
3. `ir/` owns the target-independent representation produced after parsing and semantic validation.

The JSON file loader and parser remain outside SPARK. The validator turns the JSON verb definitions into a normal Ada table. All subsequent frontend phases use the validated table and SPARK-compatible core types.
