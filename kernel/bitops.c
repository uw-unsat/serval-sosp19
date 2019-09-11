// SPDX-License-Identifier: GPL-2.0-or-later
/* bit search implementation
 *
 * Copyright (C) 2004 Red Hat, Inc. All Rights Reserved.
 * Written by David Howells (dhowells@redhat.com)
 *
 * Copyright (C) 2008 IBM Corporation
 * 'find_last_bit' is written by Rusty Russell <rusty@rustcorp.com.au>
 * (Inspired by David Howell's find_next_bit implementation)
 *
 * Rewritten by Yury Norov <yury.norov@gmail.com> to decrease
 * size and improve performance, 2015.
 */

#include <sys/bitmap.h>
#include <sys/bitops.h>
#include <asm/bitops.h>

/*
 * Find the first set bit in a memory region.
 */
unsigned long find_first_bit(const unsigned long *addr, unsigned long size)
{
        unsigned long idx;

        for (idx = 0; idx * BITS_PER_LONG < size; idx++) {
                if (addr[idx])
                        return min(idx * BITS_PER_LONG + __ffs(addr[idx]), size);
        }

        return size;
}

unsigned long find_last_bit(const unsigned long *addr, unsigned long size)
{
        if (size) {
                unsigned long val = BITMAP_LAST_WORD_MASK(size);
                unsigned long idx = (size-1) / BITS_PER_LONG;

                do {
                        val &= addr[idx];
                        if (val)
                                return idx * BITS_PER_LONG + __fls(val);

                        val = ~0ul;
                } while (idx--);
        }
        return size;
}

/*
 * This is a common helper function for find_next_bit, find_next_zero_bit, and
 * find_next_and_bit. The differences are:
 *  - The "invert" argument, which is XORed with each fetched word before
 *    searching it for one bits.
 *  - The optional "addr2", which is anded with "addr1" if present.
 */
static inline unsigned long _find_next_bit(const unsigned long *addr1,
                const unsigned long *addr2, unsigned long nbits,
                unsigned long start, unsigned long invert)
{
        unsigned long tmp;

        if (start >= nbits)
                return nbits;

        tmp = addr1[start / BITS_PER_LONG];
        if (addr2)
                tmp &= addr2[start / BITS_PER_LONG];
        tmp ^= invert;

        /* Handle 1st word. */
        tmp &= BITMAP_FIRST_WORD_MASK(start);
        start = rounddown_2(start, BITS_PER_LONG);

        while (!tmp) {
                start += BITS_PER_LONG;
                if (start >= nbits)
                        return nbits;

                tmp = addr1[start / BITS_PER_LONG];
                if (addr2)
                        tmp &= addr2[start / BITS_PER_LONG];
                tmp ^= invert;
        }

        return min(start + __ffs(tmp), nbits);
}

/*
 * Find the next set bit in a memory region.
 */
unsigned long find_next_bit(const unsigned long *addr, unsigned long size,
                            unsigned long offset)
{
        return _find_next_bit(addr, NULL, size, offset, 0UL);
}

/*
 * Find the first cleared bit in a memory region.
 */
unsigned long find_first_zero_bit(const unsigned long *addr, unsigned long size)
{
        unsigned long idx;

        for (idx = 0; idx * BITS_PER_LONG < size; idx++) {
                if (addr[idx] != ~0UL)
                        return min(idx * BITS_PER_LONG + ffz(addr[idx]), size);
        }

        return size;
}

unsigned long find_next_zero_bit(const unsigned long *addr, unsigned long size,
                                 unsigned long offset)
{
        return _find_next_bit(addr, NULL, size, offset, ~0UL);
}

unsigned long find_next_and_bit(const unsigned long *addr1,
                const unsigned long *addr2, unsigned long size,
                unsigned long offset)
{
        return _find_next_bit(addr1, addr2, size, offset, 0UL);
}
