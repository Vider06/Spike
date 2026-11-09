# Quick interpreter

Planned responsibility: consume validated frontend IR, dispatch virtual instructions, coordinate VM state and memory operations, and produce structured execution results.

The interpreter must not parse source text or embed a second instruction-semantics implementation. It should call the VM packages under `../vm/`. This component is not implemented yet.
