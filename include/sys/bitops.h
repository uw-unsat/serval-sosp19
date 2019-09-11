/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <sys/types.h>
#include <sys/bitops/__ffs.h>
#include <sys/bitops/__fls.h>
#include <sys/bitops/fls64.h>

#define BITS_PER_TYPE(type)     (sizeof(type) * BITS_PER_BYTE)
#define BITS_TO_LONGS(nr)       DIV_ROUND_UP(nr, BITS_PER_TYPE(long))

#define ffz(x)  __ffs(~(x))

/**
 * ror32 - rotate a 32-bit value right
 * @word: value to rotate
 * @shift: bits to roll
 */
static inline uint32_t ror32(uint32_t word, unsigned int shift)
{
        return (word >> shift) | (word << (32 - shift));
}

unsigned long find_first_bit(const unsigned long *addr, unsigned long size);

unsigned long find_last_bit(const unsigned long *addr, unsigned long size);

unsigned long find_next_bit(const unsigned long *addr, unsigned long size,
			    unsigned long offset);

unsigned long find_first_zero_bit(const unsigned long *addr,
                                  unsigned long size);

unsigned long find_next_zero_bit(const unsigned long *addr, unsigned long size,
				 unsigned long offset);

unsigned long find_next_and_bit(const unsigned long *addr1,
		const unsigned long *addr2, unsigned long size,
		unsigned long offset);

#define for_each_set_bit(bit, addr, size)                       \
	for ((bit) = find_first_bit((addr), (size));            \
	     (bit) < (size);                                    \
	     (bit) = find_next_bit((addr), (size), (bit) + 1))

/**
 * test_bit - Determine whether a bit is set
 * @nr: bit number to test
 * @addr: Address to start counting from
 */
static inline int test_bit(int nr, const volatile unsigned long *addr)
{
	return 1UL & (addr[BIT_WORD(nr)] >> (nr & (BITS_PER_LONG-1)));
}
