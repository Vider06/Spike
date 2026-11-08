# Build backend

Build is the native-artifact path for validated frontend IR.

- [assembler/](assembler/README.md) organizes virtual instructions and resolves source-level assembly constructs.
- [encoder/](encoder/README.md) emits target-specific instruction encodings.
- [object/](object/README.md) writes object-file sections, symbols, and relocations.
- [linker/](linker/README.md) coordinates final artifact linking and external tool integration.

These are architectural boundaries for future implementation; no native build pipeline is claimed yet.
