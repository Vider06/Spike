# Parser

Planned responsibility: consume `Token_Stream` values from `../lexer/`, parse the grammar defined by `src/leng/`, and produce structured syntax with source spans.

The parser must not hardcode the token vocabulary. It should report structured diagnostics for malformed or unsupported syntax. This component is not implemented yet.
