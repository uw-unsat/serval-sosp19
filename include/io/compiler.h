/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <stdarg.h>
#include <stdint.h>
#include <stdnoreturn.h>

#ifndef __always_inline
#define __always_inline inline __attribute__((always_inline))
#endif
#define noinline                __attribute__((noinline))

#define __aligned(x)            __attribute__((aligned(x)))
#define __packed                __attribute__((packed))
#define __weak                  __attribute__((weak))

#define __printf(a, b)          __attribute__((format(printf, a, b)))
#define __malloc                __attribute__((__malloc__))

#define __pure                  __attribute__((pure))
#ifndef __attribute_const__
#define __attribute_const__     __attribute__((__const__))
#endif

#define __hidden                __attribute__((__visibility__("hidden")))

#define __must_check            __attribute__((warn_unused_result))

#define __naked                 __attribute__((__naked__))

#define __same_type(a, b)       __builtin_types_compatible_p(typeof(a), typeof(b))

#define __section(S)            __attribute__((__section__(#S)))

#define __always_unused         __attribute__((__unused__))
#define __maybe_unused          __attribute__((__unused__))
#define __used                  __attribute__((__used__))

/* Indirect macros required for expanded argument pasting, eg. __LINE__. */
#define ___PASTE(a,b) a##b
#define __PASTE(a,b) ___PASTE(a,b)

#define __UNIQUE_ID(prefix) __PASTE(__PASTE(__UNIQUE_ID_, prefix), __COUNTER__)

/* Optimization barrier */

/* The "volatile" is due to gcc bugs */
#define barrier() __asm__ __volatile__("": : :"memory")
/*
 * This version is i.e. to prevent dead stores elimination on @ptr
 * where gcc and llvm may behave differently when otherwise using
 * normal barrier(): while gcc behavior gets along with a normal
 * barrier(), llvm needs an explicit input variable to be assumed
 * clobbered. The issue is as follows: while the inline asm might
 * access any memory it wants, the compiler could have fit all of
 * @ptr into memory registers instead, and since @ptr never escaped
 * from that, it proved that the inline asm wasn't touching any of
 * it. This version works well with both compilers, i.e. we're telling
 * the compiler that the inline asm absolutely may see the contents
 * of @ptr. See also: https://llvm.org/bugs/show_bug.cgi?id=15495
 */
#define barrier_data(ptr) __asm__ __volatile__("": :"r"(ptr) :"memory")

/*
 * This macro obfuscates arithmetic on a variable address so that gcc
 * shouldn't recognize the original var, and make assumptions about it.
 *
 * This is needed because the C standard makes it undefined to do
 * pointer arithmetic on "objects" outside their boundaries and the
 * gcc optimizers assume this is the case. In particular they
 * assume such arithmetic does not wrap.
 *
 * A miscompilation has been observed because of this on PPC.
 * To work around it we hide the relationship of the pointer and the object
 * using this macro.
 *
 * Versions of the ppc64 compiler before 4.1 had a bug where use of
 * RELOC_HIDE could trash r30. The bug can be worked around by changing
 * the inline assembly constraint from =g to =r, in this particular
 * case either is valid.
 */
#define RELOC_HIDE(ptr, off)                                            \
({                                                                      \
        unsigned long __ptr;                                            \
        __asm__ ("" : "=r"(__ptr) : "0"(ptr));                          \
        (typeof(ptr)) (__ptr + (off));                                  \
})

/* Make the optimizer believe the variable can be manipulated arbitrarily. */
#define OPTIMIZER_HIDE_VAR(var)                                         \
        __asm__ ("" : "=r" (var) : "0" (var))

/*
 * Mark a position in code as unreachable.  This can be used to
 * suppress control flow warnings after asm blocks that transfer
 * control elsewhere.
 */
#define unreachable() \
        do {                                    \
                asm volatile("unimp");          \
                __builtin_unreachable();        \
        } while (0)

static __always_inline void __read_once_size(const volatile void *p, void *res, int size)
{
        switch (size) {
        case 1: *(uint8_t *)res = *(volatile uint8_t *)p; break;
        case 2: *(uint16_t *)res = *(volatile uint16_t *)p; break;
        case 4: *(uint32_t *)res = *(volatile uint32_t *)p; break;
        case 8: *(uint64_t *)res = *(volatile uint64_t *)p; break;
        default:
                barrier();
                __builtin_memcpy((void *)res, (const void *)p, size);
                barrier();
        }
}

static __always_inline void __write_once_size(volatile void *p, void *res, int size)
{
        switch (size) {
        case 1: *(volatile uint8_t *)p = *(uint8_t *)res; break;
        case 2: *(volatile uint16_t *)p = *(uint16_t *)res; break;
        case 4: *(volatile uint32_t *)p = *(uint32_t *)res; break;
        case 8: *(volatile uint64_t *)p = *(uint64_t *)res; break;
        default:
                barrier();
                __builtin_memcpy((void *)p, (const void *)res, size);
                barrier();
        }
}

/*
 * Prevent the compiler from merging or refetching reads or writes. The
 * compiler is also forbidden from reordering successive instances of
 * READ_ONCE, WRITE_ONCE and ACCESS_ONCE (see below), but only when the
 * compiler is aware of some particular ordering.  One way to make the
 * compiler aware of ordering is to put the two invocations of READ_ONCE,
 * WRITE_ONCE or ACCESS_ONCE() in different C statements.
 *
 * In contrast to ACCESS_ONCE these two macros will also work on aggregate
 * data types like structs or unions. If the size of the accessed data
 * type exceeds the word size of the machine (e.g., 32 bits or 64 bits)
 * READ_ONCE() and WRITE_ONCE() will fall back to memcpy(). There's at
 * least two memcpy()s: one for the __builtin_memcpy() and then one for
 * the macro doing the copy of variable - '__u' allocated on the stack.
 *
 * Their two major use cases are: (1) Mediating communication between
 * process-level code and irq/NMI handlers, all running on the same CPU,
 * and (2) Ensuring that the compiler does not  fold, spindle, or otherwise
 * mutilate accesses that either do not require ordering or that interact
 * with an explicit memory barrier or atomic instruction that provides the
 * required ordering.
 */

#define READ_ONCE(x)                                                    \
({                                                                      \
        union { typeof(x) __val; char __c[1]; } __u;                    \
        __read_once_size(&(x), __u.__c, sizeof(x));                     \
        __u.__val;                                                      \
})

#define WRITE_ONCE(x, val)                                              \
({                                                                      \
        union { typeof(x) __val; char __c[1]; } __u =                   \
                { .__val = (typeof(x)) (val) };                         \
        __write_once_size(&(x), __u.__c, sizeof(x));                    \
        __u.__val;                                                      \
})
