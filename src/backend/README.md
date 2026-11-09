# Backends

Backends consume validated frontend IR. They do not lex, parse, or reinterpret source syntax.

- [quick/](quick/README.md) executes IR through the virtual machine.
- [build/](build/README.md) assembles IR into target artifacts.

Both paths must preserve the semantics defined by the Spike virtual ISA.
