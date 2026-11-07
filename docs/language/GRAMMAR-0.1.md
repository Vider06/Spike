# Spike 0.1 source syntax and grammar draft

**Status:** Custom syntax direction accepted; grammar proposed

## Goals

Spike syntax should be easy to scan while preserving explicit low-level operations. It must not silently allocate memory, create stack frames, infer an ABI, or insert hidden calls. It is not required to be source-compatible with NASM, GAS, FASM, C, or Rust.

## Candidate conventions

- One statement per line.
- Labels end with a colon.
- Register spelling is consistent, provisionally R0 through R15.
- Memory operands use brackets.
- Decimal, hexadecimal, and binary integer literals.
- A single explicitly selected comment marker.
- Directives have a distinct namespace or prefix.

## Illustrative syntax (not normative)

    section code
    entry:
        mov R0, 10
        mov R1, 20
        add R2, R0, R1
    again:
        sub R2, R2, 1
        branch.nz again
        halt
    section data
    message:
        data.bytes "Spike", 10

This illustration uses a three-operand ADD only to show one possible form. The final grammar must choose a consistent operand convention.

## Structural grammar sketch

    program        = { statement } ;
    statement      = [ label ] [ instruction | directive ] ;
    label          = identifier, ":" ;
    instruction    = mnemonic, [ operand_list ] ;
    operand_list   = operand, { ",", operand } ;
    operand         = register | integer | memory_operand | symbol | expression ;
    memory_operand = "[", address_expression, "]" ;

This is not a complete grammar. Whitespace, comments, escapes, numeric overflow, precedence, namespaces, and line continuation still need normative productions.

## Directives and symbols

Candidate directives cover code/data section selection, byte and integer data emission, alignment, symbol visibility, and constants. Each directive must state whether it changes assembly state, emits bytes, reserves storage, or creates metadata. Directives do not execute as VM instructions.

Duplicate symbols and unresolved references are diagnostics, never silent overwrites. Branch labels should be the initial default for control-flow targets.

## Pseudo-instructions

Each pseudo-instruction has a documented deterministic expansion or explicitly specified variable size, including register clobbers, flag effects, and memory effects.

## Decisions before grammar freeze

Mnemonic case sensitivity; comments; directive spelling; two- versus three-operand arithmetic; width notation; symbol scope; string escaping; expression precedence; and include/module behavior.
