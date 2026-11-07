# x86-64 native backend design

**Status:** Proposed first backend profile

## Responsibility

The backend implements the Spike virtual ISA; it does not define it. It owns instruction selection, register allocation, spills, encoding, symbol fixups, relocations, object emission, and host integration.

## Register mapping

Do not permanently map every virtual register to a physical x86-64 GPR. Host ABI constraints, RSP, implicit operands, temporaries, helper calls, and caller/callee-saved rules make this unsafe. Use a register allocator or a simple spill strategy. Preserve every live virtual value across helper calls.

The virtual SP is not automatically native RSP. If native stack storage represents virtual memory, its layout and translation must be explicit.

## Flags and arithmetic

Spike flags are virtual state. The backend may use x86 condition flags only when their exact meaning and lifetime match the Spike operation. Otherwise materialize virtual flags explicitly.

ADD/SUB may map directly when widths and flag semantics match. MUL must respect result width and implicit operands. x86 DIV has implicit operands and faults on zero or quotient overflow; Spike must define its own behavior first. Shift-count masking and logical flag updates must also be specified before lowering.

## Memory and relocations

Lower virtual addresses according to the memory model. RIP-relative addressing is useful for static symbols but is not a universal replacement for virtual addresses. Relocation type, addend, and place must match the exact instruction field and ELF ABI.

## ELF output

For hosted Linux x86-64, ELF64 relocatable output is proposed. Typical sections include text, read-only data, data, BSS, symbol tables, and relocation sections. Use correct section types and permissions; avoid RWX by default. Prefer a standard external linker initially.

## Validation

Disassemble emitted objects independently. Inspect headers, sections, symbols, and relocations. Test immediate boundaries, short/long branch fixups, register pressure, spills, and ABI boundaries. Differential tests are required for every instruction claimed supported.
