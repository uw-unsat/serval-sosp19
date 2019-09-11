/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (C) 2015 Regents of the University of California
 */

#pragma once

#ifdef __ASSEMBLER__
#define __ASM_STR(x)    x
#else
#define __ASM_STR(x)    #x
#endif

#if __riscv_xlen == 64
#define __REG_SEL(a, b) __ASM_STR(a)
#elif __riscv_xlen == 32
#define __REG_SEL(a, b) __ASM_STR(b)
#else
#error "Unexpected __riscv_xlen"
#endif

#define REG_L           __REG_SEL(ld, lw)
#define REG_S           __REG_SEL(sd, sw)
#define SZREG           __REG_SEL(8, 4)
#define LGREG           __REG_SEL(3, 2)

#define STACK_ALIGN     16

#if __SIZEOF_POINTER__ == 8
#define RISCV_PTR       __ASM_STR(.dword)
#define RISCV_SZPTR     __ASM_STR(8)
#define RISCV_LGPTR     __ASM_STR(3)
#elif __SIZEOF_POINTER__ == 4
#define RISCV_PTR       __ASM_STR(.word)
#define RISCV_SZPTR     __ASM_STR(4)
#define RISCV_LGPTR     __ASM_STR(2)
#else
#error "Unexpected __SIZEOF_POINTER__"
#endif

#if (__SIZEOF_INT__ == 4)
#define RISCV_INT       __ASM_STR(.word)
#define RISCV_SZINT     __ASM_STR(4)
#define RISCV_LGINT     __ASM_STR(2)
#else
#error "Unexpected __SIZEOF_INT__"
#endif

#if (__SIZEOF_SHORT__ == 2)
#define RISCV_SHORT     __ASM_STR(.half)
#define RISCV_SZSHORT   __ASM_STR(2)
#define RISCV_LGSHORT   __ASM_STR(1)
#else
#error "Unexpected __SIZEOF_SHORT__"
#endif
