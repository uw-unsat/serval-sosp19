#!/usr/bin/env bash


COMMON_KERNEL="""
    include/asm/csr.h
    include/asm/pmp.h
    include/asm/entry.h
    include/asm/pgtable.h
    include/asm/ptrace.h
    include/asm/page.h
    include/io/compiler.h
    include/io/const.h
    include/io/sizes.h
    include/io/linkage.h
    include/io/build_bug.h
    include/asm/tlbflush.h
    include/asm/csr_bits/status.h
    include/asm/setup.h
    include/sys/errno.h
    include/sys/types.h
    include/sys/init.h
    include/sys/string.h
    include/sys/bug.h
    bios/entry.S
    bios/boot/head.S
    kernel/smp.c
    kernel/string.c
    kernel/traps.c
"""

echo
echo "=== Komodo implementation ==="
cloc \
    monitors/komono/*.c \
    monitors/komono/*.h \
    include/uapi/komono/*.h \
    $COMMON_KERNEL

echo
echo "=== Komodo specification ==="
cloc \
    monitors/komono/verif/spec.rkt \
    monitors/komono/verif/state.rkt \
    monitors/komono/verif/ni2.rkt \


echo
echo "=== CertiKOS implementation ==="
cloc \
    monitors/isomon/*.c \
    monitors/isomon/*.h \
    include/uapi/isomon/*.h \
    $COMMON_KERNEL


echo
echo "=== CertiKOS specification ==="
cloc \
    monitors/isomon/verif/spec.rkt \
    monitors/isomon/verif/state.rkt \
    monitors/isomon/verif/ni2.rkt \

echo
echo "=== Serval framework total ==="
cloc serval/serval/lib \
    serval/serval/spec \
    serval/serval/lang \

echo
echo "=== LLVM verifier ==="
cloc serval/serval/llvm.rkt \
    serval/serval/llvm \

echo
echo "=== RISC-V verifier ==="
cloc serval/serval/riscv

echo
echo "=== BPF verifier ==="
cloc serval/serval/bpf.rkt

echo
echo "=== x32 verifier ==="
cloc serval/serval/x32