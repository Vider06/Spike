# Source layout

Spike source code is grouped by architectural responsibility:

- [frontend/](frontend/README.md) turns source text into validated intermediate representation.
- [backend/](backend/README.md) consumes that representation through independent execution/build backends.
- [leng/](leng/README.md) contains the machine-readable language definition and its JSON modules.

The frontend and backend communicate through IR. Backend code must not reimplement source lexing or parsing.
