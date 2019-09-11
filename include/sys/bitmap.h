/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <sys/bitops.h>
#include <sys/string.h>

#define DECLARE_BITMAP(name,bits) \
        unsigned long name[BITS_TO_LONGS(bits)]

#define BITMAP_FIRST_WORD_MASK(start) (~0UL << ((start) & (BITS_PER_LONG - 1)))
#define BITMAP_LAST_WORD_MASK(nbits) (~0UL >> (-(nbits) & (BITS_PER_LONG - 1)))

#define small_const_nbits(nbits) \
        (__builtin_constant_p(nbits) && (nbits) <= BITS_PER_LONG)

extern int __bitmap_subset(const unsigned long *bitmap1,
                           const unsigned long *bitmap2, unsigned int nbits);

static inline void bitmap_fill(unsigned long *dst, unsigned int nbits)
{
        if (small_const_nbits(nbits))
                *dst = ~0UL;
        else {
                unsigned int len = BITS_TO_LONGS(nbits) * sizeof(unsigned long);
                memset(dst, 0xff, len);
        }
}

static inline void bitmap_zero(unsigned long *dst, unsigned int nbits)
{
        if (small_const_nbits(nbits))
                *dst = 0UL;
        else {
                unsigned int len = BITS_TO_LONGS(nbits) * sizeof(unsigned long);
                memset(dst, 0, len);
        }
}

static inline int bitmap_subset(const unsigned long *src1,
                        const unsigned long *src2, unsigned int nbits)
{
        if (small_const_nbits(nbits))
                return ! ((*src1 & ~(*src2)) & BITMAP_LAST_WORD_MASK(nbits));
        else
                return __bitmap_subset(src1, src2, nbits);
}
