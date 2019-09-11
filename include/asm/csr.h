#pragma once

#include <sys/errno.h>
#include <asm/csr_bits/status.h>
#include <asm/csr_bits/edeleg.h>
#include <asm/csr_bits/ideleg.h>
#include <asm/csr_bits/ip.h>
#include <asm/csr_bits/ie.h>
#include <asm/csr_bits/cause.h>
#include <asm/csr_bits/pmpcfg.h>
#include <asm/csr_bits/satp.h>

#ifndef __ASSEMBLER__

#define csr_swap(csr, val)                                      \
({                                                              \
        unsigned long __v = (unsigned long)(val);               \
        __asm__ __volatile__ ("csrrw %0, " #csr ", %1"          \
                              : "=r" (__v) : "rK" (__v)         \
                              : "memory");                      \
        __v;                                                    \
})

#define csr_read(csr)                                           \
({                                                              \
        register unsigned long __v;                             \
        __asm__ __volatile__ ("csrr %0, " #csr                  \
                              : "=r" (__v) :                    \
                              : "memory");                      \
        __v;                                                    \
})

#define csr_write(csr, val)                                     \
({                                                              \
        unsigned long __v = (unsigned long)(val);               \
        __asm__ __volatile__ ("csrw " #csr ", %0"               \
                              : : "rK" (__v)                    \
                              : "memory");                      \
})

#define csr_read_set(csr, val)                                  \
({                                                              \
        unsigned long __v = (unsigned long)(val);               \
        __asm__ __volatile__ ("csrrs %0, " #csr ", %1"          \
                              : "=r" (__v) : "rK" (__v)         \
                              : "memory");                      \
        __v;                                                    \
})

#define csr_set(csr, val)                                       \
({                                                              \
        unsigned long __v = (unsigned long)(val);               \
        __asm__ __volatile__ ("csrs " #csr ", %0"               \
                              : : "rK" (__v)                    \
                              : "memory");                      \
})

#define csr_read_clear(csr, val)                                \
({                                                              \
        unsigned long __v = (unsigned long)(val);               \
        __asm__ __volatile__ ("csrrc %0, " #csr ", %1"          \
                              : "=r" (__v) : "rK" (__v)         \
                              : "memory");                      \
        __v;                                                    \
})

#define csr_clear(csr, val)                                     \
({                                                              \
        unsigned long __v = (unsigned long)(val);               \
        __asm__ __volatile__ ("csrc " #csr ", %0"               \
                              : : "rK" (__v)                    \
                              : "memory");                      \
})

/*
 * Safe access to CSRs.
 *
 * This is used only in M-mode for now, so just use mtvec.
 */

#define csr_write_safe(csr, val)                                \
({                                                              \
        int __err;                                              \
        unsigned long __tmp;                                    \
        unsigned long __v = (unsigned long)(val);               \
        asm volatile("   la     %[tmp], 2f\n"                   \
                     "   csrrw  %[tmp], mtvec, %[tmp]\n"        \
                     "   csrw   " #csr ", %[v]\n"               \
                     "   li     %[err], 0\n"                    \
                     "1: csrw   mtvec, %[tmp]\n"                \
                     "          .section .fixup,\"ax\"\n"       \
                     "          .balign 4\n"                    \
                     "2: li     %[err], %[fault]\n"             \
                     "   j      1b\n"                           \
                     "          .previous\n"                    \
                     : [err] "=r" (__err), [tmp] "=&r" (__tmp)  \
                     : [v] "rK" (__v), [fault] "i" (-EIO)       \
                     : "memory");                               \
        __err;                                                  \
})

#endif /* __ASSEMBLER__ */
