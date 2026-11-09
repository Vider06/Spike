# Lexer phase 1

The Spike 0.2 lexer recognizes source forms without knowing instruction names
or instruction semantics.

## Token contract

Each token stores its kind, zero-based half-open byte offsets, and one-based
line and column. Token kinds are Word, Quoted_Text, Left_Bracket,
Right_Bracket, Comma, Flag, Newline, Indentation, and Comment. Indentation
width is stored in the auxiliary field. Comments begin with ^^ and end before
the line break. The lexer never classifies a word as a verb, variable, type,
or keyword.

## Form checks

- No horizontal whitespace is permitted immediately inside square brackets.
- A comma must have horizontal whitespace on both sides.
- Quoted text must close on the same line; backslash escapes the next byte.
- A flag must contain an identifier after its -- prefix.
- Newline and indentation are separate tokens.

Indentation width counts source whitespace bytes; tab-stop expansion is not
performed in this phase. Columns and offsets are byte-based. The lexer returns
the first structured diagnostic (code, line, column), rather than raising an
exception. The bounded token buffer is limited to 16,384 tokens.
