# Serval repository

This repository contains the code and experiments for the SOSP'19 paper
[Scaling symbolic evaluation for automated
verification of systems code with Serval](https://unsat.cs.washington.edu/papers/nelson-serval.pdf).

Serval is a tool for building automated verifiers for systems code.

This file describes the high-level structure of the code,
see `EXPERIMENTS.md` for details on how to run the experiments yourself.

## Serval package

`serval/`: The source of the Serval verification package.

`serval/serval/lib/`: Core Serval functionality, including
memory model and unit testing libraries.

`serval/serval/riscv/`: Verifier for RISC-V programs,
including objdump parser, instruction encoder, and symbolic
interpreter.

`serval/serval/x32/`: Verifier for i386 programs.

`serval/serval/spec/`: Library for writing system specifications.

`serval/serval/llvm.rkt`: Verifier for LLVM programs.

`serval/serval/doc`: API reference documentation

## Security monitors

`monitors/`: Implementation and specifications
of security monitors.

`monitors/*/verif/`: Specifications and verification infrastructure
for security monitors.

`monitors/komodo/`: Our port of Komodo.
`monitors/certikos/`: Our port of CertiKOS.
`monitors/keystone/`: Our port of Keystone.
`monitors/toymon/`: A toy security monitor for testing.

`kernel/`: Common kernel functionality.
`bios/`: M-mode boot code.
`include/`: Kernel / security monitor headers.

## BPF JIT

`bpf/jit/riscv64.rkt`: Linux BPF to RV64 JIT.

`bpf/jit/x32.rkt`: Linux BPF to i386 JIT.

## Other infrastructure

`racket/test/`: Code for testing Serval functionality.

`racket/llvm-rosette/`: Utility for compiling LLVM IR to
Racket structures.

## Licenses

Code in this repository is licensed under the GPLv2 license, found in the `LICENSE` file.

Some code in `kernel/`, `bpf/` and `include/` is adapted from the Linux kernel.

`monitors/komodo/monitor.c` is based on the original Komodo implementation.

`racket/test/riscv-tests` is adapted from the RISC-V test suite.
