# Quick virtual machine

The VM provides the execution substrate used by the Quick interpreter.

- `state/`: registers, program counter, flags, and execution status.
- `memory/`: bounded virtual memory and access permissions.
- `stack/`: bounded stack operations.
- `instructions/`: virtual instruction semantics.

These packages are runtime primitives, not a parser or a source-level interpreter.
