# Spike Language Specification

**Specification version:** 0.1-draft  
**Status:** Initial design baseline  
**Project:** Spike  
**Repository:** https://github.com/Vider06/Spike

---

## 1. Purpose

Spike is a low-level programming language designed to make machine-level programming easier to read and write without hiding the machine from the programmer.

Spike is intended for systems software, including:

- Operating-system kernels and kernel components
- Bootloaders
- Device drivers
- Firmware
- Runtime and execution-environment components
- Other software that requires explicit control over machine resources

Spike is not intended to be a conventional high-level language that happens to compile to assembly. Its core programming model is instruction-oriented and machine-conscious.

The guiding principle is:

> **What you write is what the machine is asked to execute.**

This principle requires explicit and predictable semantics. It does not prohibit assembler directives or pseudo-instructions, but any construct that expands into multiple machine instructions must be identifiable and documented.

## 2. Design principles

The language and its tooling shall be designed around the following principles.

### 2.1 Explicit machine control

A Spike program must be able to express, directly and predictably:

- Register operations
- Loads and stores
- Arithmetic and logical operations
- Comparisons and condition flags, where supported by the target
- Control-flow transfers, including conditional and unconditional branches
- Stack manipulation
- Calls and returns
- Address calculations
- Target-specific system or privileged operations, where supported

The language must not require hidden runtime services to perform these operations.

### 2.2 Readability without high-level abstraction

Spike should use clear, consistent syntax and meaningful instruction forms. Readability must not come at the cost of concealing memory access, control flow, register effects, or other machine-visible behavior.

Convenience constructs may be considered when their expansion and effects remain explicit.

### 2.3 Predictable costs and effects

A programmer must be able to determine the machine-level consequences of a source construct from the language and target documentation.

The implementation must not silently introduce:

- Garbage collection
- Automatic heap allocation
- Implicit ownership or reference-counting machinery
- Hidden stack frames
- Unrequested runtime checks
- Unspecified helper calls
- Unspecified register preservation

Any optional feature that introduces such behavior must make that behavior explicit and opt-in.

### 2.4 Target awareness

Machine instructions, registers, calling conventions, system interfaces, and executable formats are target-dependent. Spike must represent these differences explicitly rather than pretending that all processors expose an identical machine.

### 2.5 One language, two execution paths

Spike is planned to provide two ways to execute a program:

1. **Quick mode** for rapid execution and testing.
2. **Native mode** for assembling source into native machine code and producing a target-native artifact.

Both modes must implement the same language and instruction semantics. They must not become two subtly different dialects.

## 3. Language and toolchain terminology

The following terms have specific meanings in this specification.

| Term | Meaning |
|---|---|
| Spike source | A program written in the Spike language |
| Target | A processor architecture and its applicable execution environment |
| ISA | The instruction set architecture exposed by a target |
| Assembler | The tool that translates Spike instructions and directives into machine-code output |
| Encoder | The component that encodes a target instruction as its machine-code representation |
| Quick Engine | The component that executes Spike programs in Quick mode |
| Native artifact | The machine-code output or executable produced for a target |
| Directive | A source construct that controls assembly or output but is not itself a CPU instruction |
| Pseudo-instruction | A source-level instruction form that expands into one or more real target instructions |

Spike is an assembler-oriented language. Native mode is not defined as a conventional high-level-language compilation pipeline. An implementation may use internal representations to share parsing, validation, and semantics, but such internal representations do not change the language's programming model.

## 4. Execution modes

### 4.1 Quick mode

Quick mode is intended for fast iteration, testing, and debugging.

Proposed command:

```sh
spike run program.spike
```

Quick mode may use an interpreter, an instruction-level virtual machine, or another execution mechanism. The implementation strategy is not fixed by this specification.

Regardless of implementation, Quick mode must preserve the observable semantics of the selected Spike target. It must not silently reinterpret an instruction to mean something different from its native target definition.

If the host machine cannot directly execute the selected target's instructions, Quick mode must provide an appropriate execution mechanism or report that the selected target is unsupported. It must not silently substitute host-architecture behavior.

### 4.2 Native mode

Native mode assembles Spike source into machine code for a selected target.

Proposed command:

```sh
spike build program.spike
```

The assembler and encoder must produce instruction encodings defined by the selected target ISA. The output may be a raw machine-code object or a platform executable, depending on the requested output format and supported toolchain features.

Native mode must not require a high-level compiler as an intermediate user-facing language stage.

### 4.3 Semantic consistency

Quick mode and Native mode must agree on the meaning of every supported instruction and language construct.

For a given source program, target, and defined initial machine state, both modes must produce equivalent architecturally observable results, subject to explicitly documented differences such as host I/O integration, debugging facilities, or unsupported privileged operations.

The project must maintain tests that compare the behavior of both modes wherever both are available.

## 5. Machine model

Spike programs operate on an explicitly selected target machine.

A target definition must specify, at minimum:

- Architecture and ISA revision
- Register set and register widths
- Instruction encodings
- Operand forms and legal combinations
- Arithmetic and logical behavior
- Condition-code or flag behavior, if present
- Memory addressing rules
- Alignment requirements
- Endianness
- Control-flow behavior
- Stack conventions, if defined by the target ABI
- Privilege restrictions and system interfaces relevant to supported instructions

The exact initial target and its supported ISA subset remain open decisions for the 0.1 design process.

### 5.1 Registers

Register names and properties are target-defined. Spike must not invent a universal register set that obscures the actual target architecture.

The language should provide a consistent way to refer to target registers while preserving their architectural identity and width.

Register aliases, if supported, must be documented and must not hide register usage.

### 5.2 Memory

Memory access must be explicit.

A load or store must make its access operation and relevant address expression visible in source. The target definition must specify access width, sign or zero extension behavior, alignment constraints, and any relevant architectural effects.

Spike 0.1 does not define automatic memory management. Allocation, mapping, ownership, and lifetime management remain the responsibility of the program or an explicitly invoked runtime or operating-system interface.

### 5.3 Stack

Stack operations must be explicit or use clearly documented target instructions. The language must not silently create stack frames or change the stack pointer.

Any optional function or procedure abstraction must document its effects on the stack and registers.

### 5.4 Control flow

Branches and jumps must have explicit semantics. Conditional branches must identify the condition they test, whether through a target flag model or an explicit comparison result.

Labels identify control-flow destinations. Their final syntax and scoping rules remain to be specified.

## 6. Source language structure

The final grammar is not yet frozen. The following is an illustrative design direction, not a normative grammar:

```asm
; Illustrative Spike syntax — subject to design review

section .text

start:
    mov rax, 1
    mov rdi, 1
    load rsi, message
    mov rdx, message_length
    syscall
    halt

section .data

message:
    bytes "Hello from Spike", 10
message_length:
    constant 17
```

This example communicates the intended readability and explicitness. It does not yet commit Spike to x86-64, Linux system calls, these register names, these directives, or this exact syntax.

The language specification must eventually define:

- Lexical rules, comments, identifiers, literals, and numeric bases
- Instruction statement grammar
- Operand grammar and expression evaluation
- Labels and symbol resolution
- Directives and data declarations
- Pseudo-instruction syntax and expansion rules
- Sections and alignment
- Include and module behavior, if supported
- Error handling and diagnostics

## 7. Instructions, directives, and pseudo-instructions

### 7.1 Real instructions

A real instruction corresponds to an instruction defined by the selected target ISA. Its operands, encoding, effects, exceptions, and availability must be defined by the target documentation.

### 7.2 Directives

Directives control assembly, symbol definition, data emission, layout, or output generation. They are not CPU instructions and must be distinguishable from executable instructions.

### 7.3 Pseudo-instructions

Pseudo-instructions may improve readability or provide convenient forms, but they must have a documented expansion.

For every pseudo-instruction, the target documentation must specify:

- Whether it always expands to one instruction or may expand to several
- Its exact expansion rules
- Any temporary registers it uses
- Any flags or machine state it may modify
- Any size or alignment implications

The assembler must not conceal material side effects.

## 8. Functions, calling conventions, and system interfaces

The core language must preserve the ability to write code without using functions or a conventional ABI.

If function-oriented syntax is provided, it must remain compatible with explicit control over calls, returns, stack state, and register preservation.

Calling conventions are target- and platform-specific. They must be documented as ABI profiles rather than assumed to be universal Spike behavior.

System calls, interrupts, privileged instructions, and firmware interfaces are also target- and environment-specific. Spike must expose them without pretending that one operating system's interface is part of every target.

The exact syntax and abstraction level for these facilities remain open.

## 9. Native output and linking

Native output is target-specific.

A native build may eventually support:

- Raw machine-code output
- Object files
- Platform executable formats
- Linking against compatible object files and libraries

The initial executable format, object format, linker responsibilities, relocation model, and supported operating systems have not yet been selected.

The implementation must not claim that an artifact is a native executable unless it conforms to the selected platform's executable format and ABI requirements.

## 10. Diagnostics and debugging

Spike tooling should provide precise diagnostics for:

- Invalid syntax
- Unknown instructions or directives
- Invalid operand combinations
- Register-width mismatches
- Undefined or duplicate symbols
- Invalid branch targets
- Unsupported target features
- Encoding failures
- Invalid or unsupported execution requests

Where possible, diagnostics should identify the source location and explain the target-specific rule that was violated.

Quick mode should be designed to support useful debugging, including visibility into machine state. The exact debugger interface remains open.

## 11. Toolchain implementation

The implementation language of the Spike toolchain is separate from the Spike programming language itself.

Ada and SPARK are the current proposed implementation direction:

- Ada may be used for general toolchain components and operating-system integration.
- SPARK may be used for components whose design and dependencies permit formal verification.
- GNAT and GNATprove are candidate compiler and proof tools.

This is an implementation proposal, not a requirement imposed on Spike programs or on third-party Spike toolchains. The project must identify concrete proof obligations before claiming that a component is formally verified.

## 12. Portability and target support

Portability must not erase architectural differences.

A Spike source file that uses target-specific instructions is expected to identify or require a compatible target. A program may be portable across targets only when it restricts itself to constructs with explicitly defined compatible behavior or provides target-specific implementations.

The project should keep the language's common syntax and tooling model distinct from target-specific instruction definitions and ABI profiles.

The initial supported target, minimum ISA subset, operating-system environment, and output format are pending decisions.

## 13. Non-goals

The following are not goals of the initial 0.1 baseline:

- Hiding machine instructions behind high-level abstractions
- Requiring automatic memory management
- Requiring a garbage-collected runtime
- Requiring a conventional high-level compiler pipeline
- Making all architectures appear identical
- Guaranteeing that every program is portable across targets
- Requiring self-hosting in the first implementation

Self-hosting may be a long-term project goal, but it is not a prerequisite for the first usable toolchain.

## 14. Conformance

An implementation claiming conformance to this specification must:

1. Identify the Spike specification version it implements.
2. Identify the target architecture, ISA revision, and supported instruction subset.
3. Document all supported directives and pseudo-instructions.
4. Preserve the specified instruction semantics in every supported execution mode.
5. Reject unsupported or invalid constructs rather than silently assigning them different meanings.
6. Document output-format and ABI support accurately.
7. Provide tests for parsing, instruction validation, encoding, and execution behavior appropriate to its claimed support.

A target-specific implementation may support only a subset of Spike while remaining useful, but it must state that subset clearly.

## 15. Open design decisions

The following decisions must be resolved before this draft can become a stable 0.1 specification.

| Area | Open question |
|---|---|
| Initial target | x86-64, AArch64, or another architecture? |
| Target strategy | One initial target with later expansion, or a multi-target architecture from the start? |
| Syntax | Which instruction, operand, label, and directive syntax should be normative? |
| Quick mode | Direct interpreter, instruction-level VM, or another implementation? |
| Memory model | Which address-space, width, alignment, and data-layout rules are exposed? |
| Functions | Should function declarations exist, and how much ABI behavior should they express? |
| Directives | Which sections, data declarations, alignment, constants, and symbol directives are required? |
| Pseudo-instructions | Are they included in the initial subset, and how are expansions exposed? |
| Output | Raw binary, object format, executable format, or a staged approach? |
| Linking | Built-in linker, external linker integration, or both? |
| System interfaces | Which operating-system, firmware, and privileged interfaces are in scope? |
| Debugging | What machine-state inspection and debug information should Quick mode provide? |

These questions are intentionally visible. They must be decided through design discussion and recorded in the specification rather than being settled accidentally by an early implementation.

## 16. Versioning of this specification

This document is an initial draft and establishes the project's design direction. It is not a claim that every syntax detail, target, instruction, or ABI has already been finalized.

Changes that alter instruction semantics, machine-state behavior, source compatibility, or target conformance must be reflected in the specification version and documented explicitly.

---

**End of Spike Language Specification 0.1-draft.**
