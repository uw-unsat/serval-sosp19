/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#ifndef __ASSEMBLER__

#include <stdint.h>

#define __AC(X,Y)       (X##Y)
#define _AC(X,Y)        __AC(X,Y)
#define _AT(T,X)        ((T)(X))

typedef uint16_t le16_t;
typedef uint16_t be16_t;
typedef uint32_t le32_t;
typedef uint32_t be32_t;
typedef uint64_t le64_t;
typedef uint64_t be64_t;

#else   /* !__ASSEMBLER__ */

#define _AC(X,Y)        X
#define _AT(T,X)        X

#define UINT32_C(x)     x
#define UINT64_C(x)     x

#endif  /* __ASSEMBLER__ */

#define BIT(nr)         (_AC(1, UL) << (nr))
#define BIT_32(nr)      (UINT32_C(1) << (nr))
#define BIT_64(nr)      (UINT64_C(1) << (nr))

/*
 * Create a contiguous bitmask starting at bit position @l and
 * ending at * position @h. For example, GENMASK_64(39, 21) gives
 * the 64-bit vector 0x000000ffffe00000.
 */
#define GENMASK_32(h, l) \
        (((~UINT32_C(0)) - BIT_32(l) + 1) & (~UINT32_C(0) >> (31 - (h))))

#define GENMASK_64(h, l) \
        (((~UINT64_C(0)) - BIT_64(l) + 1) & (~UINT64_C(0) >> (63 - (h))))
