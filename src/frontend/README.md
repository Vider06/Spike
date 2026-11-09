# Frontend

The frontend owns source-language processing and target-independent representations.

1. `lexer/` converts source bytes into positioned lexical tokens. The phase-one
   implementation is the SPARK package `Spike_Lexer`; it does not classify
   words as verbs or interpret their operands.
2. `parser/` consumes tokens and the validated JSON verb table to construct
   syntax trees.
3. `ir/` owns the target-independent representation produced after parsing
   and semantic validation.

The earlier JSON-configured lexer remains temporarily as a compatibility
implementation for existing API clients. New frontend work must use
`Spike_Lexer` through `Spike_API.Lex_Source`. The compatibility implementation
will be removed when the API migration is complete.
