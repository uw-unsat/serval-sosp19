/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <stdint.h>

#if 1

#define swab16 __builtin_bswap16
#define swab32 __builtin_bswap32
#define swab64 __builtin_bswap64

#else

/*
 * There is no need to provide implementations for these calls.
 * LLVM rewrites the following swap* to llvm.bswap.i* anyway.
 */

static inline uint16_t swab16(uint16_t x)
{
        return ((x & UINT16_C(0x00ff)) << 8) |
               ((x & UINT16_C(0xff00)) >> 8);
}

static inline uint32_t swab32(uint32_t x)
{
        return ((x & UINT32_C(0x000000ff)) << 24) |
               ((x & UINT32_C(0x0000ff00)) <<  8) |
               ((x & UINT32_C(0x00ff0000)) >>  8) |
               ((x & UINT32_C(0xff000000)) >> 24);
}

static inline uint64_t swab64(uint64_t x)
{
        return ((x & UINT64_C(0x00000000000000ff)) << 56) |
               ((x & UINT64_C(0x000000000000ff00)) << 40) |
               ((x & UINT64_C(0x0000000000ff0000)) << 24) |
               ((x & UINT64_C(0x00000000ff000000)) <<  8) |
               ((x & UINT64_C(0x000000ff00000000)) >>  8) |
               ((x & UINT64_C(0x0000ff0000000000)) >> 24) |
               ((x & UINT64_C(0x00ff000000000000)) >> 40) |
               ((x & UINT64_C(0xff00000000000000)) >> 56);
}

#endif
