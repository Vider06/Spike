# Parser — Phase 3

The parser consumes positioned lexer tokens and the validated verb table. It
does not read JSON and does not contain verb-specific branches. Verb names,
operand shapes, repeated operand groups, flags, and positional separators are
resolved from metadata.

A form describes operand *groups*, not a fixed number of actual operands.
An operand declaration may set `"repeat": true`; the parser then accepts one
or more comma-separated occurrences of that shape. A repeated group may end
at a declared keyword/separator boundary or at the end of the form. This is
how `get` accepts arbitrary destination and source lists without encoding a
maximum list length in JSON. The same mechanism is available to `give`,
`calc`, and any future verb form.

The current provisional table accepts, for example:

```spike
get a , b , c , d from ["data"]=x , y , z , w
give alpha , beta , gamma
give [continue]
```

The `=` marker is tokenized explicitly, so it is distinguishable from an
identifier adjacent to a closing bracket. The grammar remains provisional
until the complete language manual is supplied.

The AST uses shared flat operand and flag-span arrays. Each statement stores
an offset and count into those arrays; there is no per-statement eight-operand
or eight-flag limit. Total input remains subject to the lexer's global source
and token resource guards. Form matching evaluates every declared form and
reports an ambiguity instead of silently choosing the first match.

The AST currently preserves statements in source order and token spans. It
does not yet perform name resolution, type checking, operation semantics, or
part-scope construction. Hierarchical part/block structure is intentionally
deferred until the evolving `part` grammar is supplied by the authoritative
manual; indentation will not be guessed as a block rule.

Blank lines and comments are ignored. The parser reports unknown verbs,
missing forms, ambiguous forms, unexpected tokens, and aggregate AST resource
exhaustion with source locations.
