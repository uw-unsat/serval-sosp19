#pragma once
#include <io/compiler.h>

/*
 * Flush entire local TLB.  'sfence.vma' implicitly fences with the instruction
 * cache as well, so a 'fence.i' is not necessary.
 */
static __always_inline void local_flush_tlb_all(void)
{
        asm volatile("sfence.vma" : : : "memory");
}
