# ADR 0002: x86-64 first native target profile

**Status:** x86 family accepted; x86-64 profile proposed

## Context

The project selected x86 as its initial target family. The proposed VM uses 64-bit registers and addresses, but x86 may refer to 16-bit, 32-bit, or 64-bit modes.

## Decision

Use x86-64 as the concrete 0.1 native profile, subject to confirmation before its encoding and ABI become stable. Exclude legacy 16-bit and 32-bit modes from the first implementation. Select a conservative CPU baseline and declare optional extensions explicitly.

## Alternatives

- IA-32: conflicts with the proposed 64-bit model.
- All x86 modes: multiplies encoder and ABI scope.
- Another ISA: contradicts the selected direction.

## Consequences

The first backend can target x86-64 encodings and potentially ELF64. Register allocation must respect host ABI constraints. x86 flags do not define Spike flags. OS ABI and privilege level remain separate choices.

## Follow-up

Confirm CPU baseline, host OS, object format, and hosted versus freestanding first use case.
