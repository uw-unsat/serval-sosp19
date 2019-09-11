#pragma once

#include <asm/setup.h>
#include <sys/types.h>

#define MAX_PHYSMEM_BITS        56

#define PAGE_SHIFT      (12)
#define PAGE_SIZE       (_AC(1, UL) << PAGE_SHIFT)
#define PAGE_MASK       (~(PAGE_SIZE - 1))

#ifndef __ASSEMBLER__

extern unsigned long va_pa_offset;

#define __pa(x)         ((uintptr_t)(x) - va_pa_offset)
#define __va(x)         ((void *)((uintptr_t)(x) + va_pa_offset))

#endif
