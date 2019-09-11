#!/usr/bin/env bash
riscv64-unknown-elf-gcc -O2 -march=rv32g -mabi=ilp32 -c *.c
