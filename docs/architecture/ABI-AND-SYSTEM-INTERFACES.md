# Spike ABI and system-interface boundaries

## Three distinct contracts

1. Virtual calling convention: calls between Spike functions.
2. Native host ABI: calls across the generated-code and host boundary.
3. Environment interface: OS, firmware, or monitor services.

## Virtual calling convention

Define argument locations, return values, caller/callee-saved virtual registers, stack alignment, return-address representation, and frame rules. Keep the first convention small and do not inherit System V register assignments without an explicit decision.

## Native host ABI

System V AMD64 is a plausible first Linux x86-64 interoperability ABI. It governs host calls, not Spike CALL/RET. Generated adapters must document clobbers, stack alignment, red-zone assumptions, unwind behavior, and symbol visibility. Windows x64 is a separate ABI.

## System services

An OS syscall is not a portable CPU instruction. Linux syscall numbers and register assignments differ from function-call ABI rules and from other systems. The architecture-neutral core should not define a universal SYSCALL with hidden host meaning.

Use an explicit environment profile or host-call boundary. Quick mode must provide matching service behavior or report that the service is unavailable; it must not silently invoke a different service.

## Privileged and freestanding programs

Kernel, bootloader, and firmware code require explicit entry contracts, privilege assumptions, memory layouts, and hardware interfaces. They are separate profiles, not ordinary hosted programs.
