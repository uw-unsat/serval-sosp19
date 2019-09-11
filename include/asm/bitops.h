#pragma once

#include <sys/types.h>

#if (BITS_PER_LONG == 64)
#define __AMO(op)       "amo" #op ".d"
#elif (BITS_PER_LONG == 32)
#define __AMO(op)       "amo" #op ".w"
#else
#error "Unexpected BITS_PER_LONG"
#endif

#define __op_bit_ord(op, mod, nr, addr, ord)                    \
        __asm__ __volatile__ (                                  \
                __AMO(op) #ord " zero, %1, %0"                  \
                : "+A" (addr[BIT_WORD(nr)])                     \
                : "r" (mod(BIT_MOD(nr)))                        \
                : "memory");

#define __op_bit(op, mod, nr, addr)                             \
        __op_bit_ord(op, mod, nr, addr, )

/* Bitmask modifiers */
#define __NOP(x)        (x)
#define __NOT(x)        (~(x))

/**
 * set_bit - Atomically set a bit in memory
 * @nr: the bit to set
 * @addr: the address to start counting from
 *
 * Note: there are no guarantees that this function will not be reordered
 * on non x86 architectures, so if you are writing portable code,
 * make sure not to rely on its reordering guarantees.
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 */
static inline void set_bit(int nr, volatile unsigned long *addr)
{
        __op_bit(or, __NOP, nr, addr);
}

/**
 * clear_bit - Clears a bit in memory
 * @nr: Bit to clear
 * @addr: Address to start counting from
 *
 * Note: there are no guarantees that this function will not be reordered
 * on non x86 architectures, so if you are writing portable code,
 * make sure not to rely on its reordering guarantees.
 */
static inline void clear_bit(int nr, volatile unsigned long *addr)
{
        __op_bit(and, __NOT, nr, addr);
}
