# Intermediate representation

The frontend IR is the stable, target-independent contract between the frontend and all backends.

It should represent validated instructions, typed operands, labels, directives, source spans, and declared effects. It must not contain x86-specific encodings or Quick-engine runtime state.

Both Quick and Build consume the same validated IR. The IR data model is not implemented yet.
