# Frontend

The frontend owns source-language processing and target-independent representations.

1. `lexer/` converts source bytes into a validated token stream.
2. `parser/` will consume tokens and construct syntax.
3. `ir/` owns the target-independent intermediate representation produced after parsing and validation.

Only the lexer is implemented today. Parser and IR directories document the agreed component boundaries; they are not placeholder implementations.
