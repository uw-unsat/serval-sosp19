/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#ifndef __ASSEMBLER__
#include <stdatomic.h>
#include <stdbool.h>
#include <stddef.h>
#include <io/nospec.h>
#include <io/sizes.h>
#include <sys/bug.h>
#include <sys/log2.h>
#include <sys/printk.h>

#define USHRT_MAX       ((u16)(~0U))
#define SHRT_MAX        ((s16)(USHRT_MAX>>1))
#define SHRT_MIN        ((s16)(-SHRT_MAX - 1))
#define INT_MAX         ((int)(~0U>>1))
#define INT_MIN         (-INT_MAX - 1)
#define UINT_MAX        (~0U)
#define LONG_MAX        ((long)(~0UL>>1))
#define LONG_MIN        (-LONG_MAX - 1)
#define ULONG_MAX       (~0UL)
//#define LLONG_MAX       ((long long)(~0ULL>>1))
#define LLONG_MIN       (-LLONG_MAX - 1)
#define ULLONG_MAX      (~0ULL)
#ifndef SIZE_MAX
#define SIZE_MAX        (~(size_t)0)
#endif
#define PHYS_ADDR_MAX   (~(phys_addr_t)0)

/**
 * container_of - cast a member of a structure out to the containing structure
 * @ptr:        the pointer to the member.
 * @type:       the type of the container struct this is embedded in.
 * @member:     the name of the member within the struct.
 *
 */
#define container_of(ptr, type, member) ({                      \
        const typeof( ((type *)0)->member ) *__mptr = (ptr);    \
        (type *)( (char *)__mptr - offsetof(type,member) );})

/* &a[0] degrades to a pointer: a different type from an array */
#define __must_be_array(a)      BUILD_BUG_ON_ZERO(__same_type((a), &(a)[0]))

#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]) + __must_be_array(arr))

/**
 * REPEAT_BYTE - repeat the value @x multiple times as an unsigned long value
 * @x: value to repeat
 *
 * NOTE: @x is not checked for > 0xff; larger values produce odd results.
 */
#define REPEAT_BYTE(x)  ((~0ul / 0xff) * (x))

/*
 * min()/max()/clamp() macros that also do
 * strict type-checking.. See the
 * "unnecessary" pointer comparison.
 */
#define __min(t1, t2, min1, min2, x, y) ({              \
        t1 min1 = (x);                                  \
        t2 min2 = (y);                                  \
        (void) (&min1 == &min2);                        \
        min1 < min2 ? min1 : min2; })

/**
 * min - return minimum of two values of the same or compatible types
 * @x: first value
 * @y: second value
 */
#define min(x, y)                                       \
        __min(typeof(x), typeof(y),                     \
              __UNIQUE_ID(min1_), __UNIQUE_ID(min2_),   \
              x, y)

#define __max(t1, t2, max1, max2, x, y) ({              \
        t1 max1 = (x);                                  \
        t2 max2 = (y);                                  \
        (void) (&max1 == &max2);                        \
        max1 > max2 ? max1 : max2; })

/**
 * max - return maximum of two values of the same or compatible types
 * @x: first value
 * @y: second value
 */
#define max(x, y)                                       \
        __max(typeof(x), typeof(y),                     \
              __UNIQUE_ID(max1_), __UNIQUE_ID(max2_),   \
              x, y)

/**
 * clamp - return a value clamped to a given range with strict typechecking
 * @val: current value
 * @lo: lowest allowable value
 * @hi: highest allowable value
 *
 * This macro does strict typechecking of @lo/@hi to make sure they are of the
 * same type as @val.  See the unnecessary pointer comparisons.
 */
#define clamp(val, lo, hi) min((typeof(val))max(val, lo), hi)

/**
 * min_t - return minimum of two values, using the specified type
 * @type: data type to use
 * @x: first value
 * @y: second value
 */
#define min_t(type, x, y)                               \
        __min(type, type,                               \
              __UNIQUE_ID(min1_), __UNIQUE_ID(min2_),   \
              x, y)

/**
 * max_t - return maximum of two values, using the specified type
 * @type: data type to use
 * @x: first value
 * @y: second value
 */
#define max_t(type, x, y)                               \
        __max(type, type,                               \
              __UNIQUE_ID(min1_), __UNIQUE_ID(min2_),   \
              x, y)

#define do_div(n, base) ({                      \
        uint32_t __base = (base);               \
        uint32_t __rem;                         \
        __rem = ((uint64_t)(n)) % __base;       \
        (n) = ((uint64_t)(n)) / __base;         \
        __rem;                                  \
 })

#define roundup(x, y) (                                 \
{                                                       \
        const typeof(y) __y = y;                        \
        (((x) + (__y - 1)) / __y) * __y;                \
}                                                       \
)

#define rounddown(x, y) (                               \
{                                                       \
        typeof(x) __x = (x);                            \
        __x - (__x % (y));                              \
}                                                       \
)

/*
 * This looks more complex than it should be. But we need to
 * get the type for the ~ right in round_down (it needs to be
 * as wide as the result!), and we want to evaluate the macro
 * arguments just once each.
 */
#define __round_mask(x, y)      ((__typeof__(x))((y)-1))
/**
 * roundup_2 - round up to next specified power of 2
 * @x: the value to round
 * @y: multiple to round up to (must be a power of 2)
 *
 * Rounds @x up to next multiple of @y (which must be a power of 2).
 * To perform arbitrary rounding up, use roundup() below.
 */
#define roundup_2(x, y)         ((((x)-1) | __round_mask(x, y))+1)
/**
 * rounddown_2 - round down to next specified power of 2
 * @x: the value to round
 * @y: multiple to round down to (must be a power of 2)
 *
 * Rounds @x down to next multiple of @y (which must be a power of 2).
 * To perform arbitrary rounding down, use rounddown() below.
 */
#define rounddown_2(x, y)       ((x) & ~__round_mask(x, y))

#define DIV_ROUND_UP(n,d)       (((n) + (d) - 1) / (d))

#define ALIGN(x, a)             __ALIGN_MASK(x, (typeof(x))(a) - 1)
#define __ALIGN_MASK(x, mask)   (((x) + (mask)) & ~(mask))
#define PTR_ALIGN(p, a)         ((typeof(p))ALIGN((uintptr_t)(p), (a)))

#define BIT_WORD(nr)            ((nr) / BITS_PER_LONG)
#define BIT_MOD(nr)             (1UL << ((nr) % BITS_PER_LONG))

typedef uint64_t        dma_addr_t;
typedef uint64_t        phys_addr_t;
typedef phys_addr_t     resource_size_t;
typedef intmax_t        ssize_t;
typedef intmax_t        off_t;

struct list_head {
        struct list_head *next, *prev;
};

extern const char hex_asc[];
#define hex_asc_lo(x)   hex_asc[((x) & 0x0f)]
#define hex_asc_hi(x)   hex_asc[((x) & 0xf0) >> 4]

static inline char *hex_byte_pack(char *buf, uint8_t byte)
{
        *buf++ = hex_asc_hi(byte);
        *buf++ = hex_asc_lo(byte);
        return buf;
}

extern const char hex_asc_upper[];
#define hex_asc_upper_lo(x)     hex_asc_upper[((x) & 0x0f)]
#define hex_asc_upper_hi(x)     hex_asc_upper[((x) & 0xf0) >> 4]

static inline char *hex_byte_pack_upper(char *buf, uint8_t byte)
{
        *buf++ = hex_asc_upper_hi(byte);
        *buf++ = hex_asc_upper_lo(byte);
        return buf;
}

int hex_to_bin(char ch);
int __must_check hex2bin(uint8_t *dst, const char *src, size_t count);
extern char *bin2hex(char *dst, const void *src, size_t count);

#endif  /* !__ASSEMBLER__ */
