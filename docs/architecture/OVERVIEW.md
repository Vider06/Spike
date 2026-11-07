# Spike 0.1 architecture overview

## Identity and boundaries

Spike defines its own low-level virtual instruction set architecture (virtual ISA). Source code targets that ISA, not x86 mnemonics. The first native backend lowers the virtual ISA to x86-64. This separates three contracts:

1. The language: syntax, operands, labels, directives, and diagnostics.
2. The virtual machine: registers, PC, flags, memory, control flow, and architectural faults.
3. The native backend: x86-64 instruction selection, register allocation, encoding, relocations, and host integration.

Quick mode interprets the virtual ISA. Native mode lowers the same validated instructions to native code. Both must implement the same semantic definitions.

## Pipeline

    Spike source
        |
    Lexer and parser
        |
    Validated virtual instructions
        |                         |
    Quick interpreter        x86-64 backend
        |                         |
    Virtual state             Native code
                                  |
                             ELF object
                                  |
                           External linker

An internal IR is an implementation choice, not a language requirement. It must preserve source locations and instruction effects.

## Proposed 0.1 machine profile

The working proposal is a 64-bit integer virtual machine with sixteen general-purpose registers, a separate PC, explicit status flags, a virtual stack pointer, and a defined address space. Register naming, SP representation, PC units, flag bits, and reset state remain to be finalized in the ISA specification.

The virtual SP is not automatically the host RSP. Virtual registers are not permanently assigned one-to-one to x86-64 registers. The backend must account for ABI constraints, temporaries, calls, and spills.

## Native target

The project selected the x86 family. Since the proposed VM is 64-bit, this documentation recommends x86-64 as the concrete first native profile. Legacy 16-bit and 32-bit x86 are outside the initial implementation proposal. The exact minimum CPU baseline and host environment must be confirmed before native artifacts become stable.

## Hosted versus privileged execution

The first usable native workflow should be hosted x86-64. Kernel, bootloader, firmware, and privileged execution require separate entry contracts, memory layouts, privilege assumptions, and system interfaces. They are goals, not automatic properties of generating an ELF file.

## Architectural invariants

- Every virtual instruction has one normative semantic definition.
- Quick and Native modes implement that definition.
- Lowering may use multiple host instructions or helpers but may not silently alter observable Spike behavior.
- Directives are assembler-time constructs, not CPU instructions.
- Pseudo-instructions document expansion, clobbers, flags, memory effects, and size.
- Host ABI and OS services are separate from the virtual ISA.
- Unsupported features fail explicitly; no approximate lowering is permitted.

## Deferred

Additional native architectures, dynamic linking, vector and floating-point state, concurrency, privileged profiles, macro systems, self-hosting, and a serialized virtual bytecode format are deferred.
