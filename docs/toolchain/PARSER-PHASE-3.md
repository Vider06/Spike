# Parser — Phase 3

The parser consumes positioned lexer tokens and the validated verb table. It
does not read JSON and does not contain verb-specific branches. Verb names,
operand shapes, flags, and positional keywords are resolved from metadata.

The initial AST is a bounded sequence of statements. Each statement records
the source token identifying its verb, the matching verb-table entry and form,
and token spans for operands and accepted flags. Token spans preserve exact
source locations without copying source strings.

A source line is accepted when exactly one declared form matches its operand
sequence, positional keywords, and trailing flags. A name accepts a word; a
value accepts a word or quoted text; bracket expressions and lists are
represented by balanced bracketed token spans. Commas separate operands.
Keywords are matched at their declared after-operand position.

The parser does not resolve names, check types, or decide operation meaning.
Those belong to later phases. The initial AST supports 512 statements, 8
operands, and 8 flags per statement. Blank lines and comments are ignored.
