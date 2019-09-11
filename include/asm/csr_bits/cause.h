#pragma once

#include <io/const.h>
#include <asm/setup.h>

#define INTR_BIT                BIT_64(XLEN - 1)

#define INTR_SOFT_U             (INTR_BIT | 0)
#define INTR_SOFT_S             (INTR_BIT | 1)
/* RESERVED                     (INTR_BIT | 2) */
#define INTR_SOFT_M             (INTR_BIT | 3)
#define INTR_TIMER_U            (INTR_BIT | 4)
#define INTR_TIMER_S            (INTR_BIT | 5)
/* RESERVED                     (INTR_BIT | 6) */
#define INTR_TIMER_M            (INTR_BIT | 7)
#define INTR_EXT_U              (INTR_BIT | 8)
#define INTR_EXT_S              (INTR_BIT | 9)
/* RESERVED                     (INTR_BIT | 10) */
#define INTR_EXT_M              (INTR_BIT | 11)

#define EXC_INST_MISALIGNED     0
#define EXC_INST_ACCESS         1
#define EXC_ILLEGAL_INST        2
#define EXC_BREAKPOINT          3
#define EXC_LOAD_MISALIGNED     4
#define EXC_LOAD_ACCESS         5
#define EXC_STORE_MISALIGNED    6
#define EXC_STORE_ACCESS        7
#define EXC_ECALL_U             8
#define EXC_ECALL_S             9
/* RESERVED                     10 */
#define EXC_ECALL_M             11
#define EXC_INST_PAGE_FAULT     12
#define EXC_LOAD_PAGE_FAULT     13
/* RESERVED                     14 */
#define EXC_STORE_PAGE_FAULT    15
