#pragma once

#include <io/sizes.h>

#ifndef CONFIG_NR_CPUS
#error "CONFIG_NR_CPUS is not defined!"
#endif

#define NR_CPUS                 CONFIG_NR_CPUS

#ifndef CONFIG_DRAM_START
#error "CONFIG_DRAM_START is not defined!"
#endif

#define DRAM_START              UINT64_C(CONFIG_DRAM_START)

/* 128GB */
#define KERNEL_VIRTUAL_START    UINT64_C(0xffffffe000000000)
#define KERNEL_VIRTUAL_SIZE     (-KERNEL_VIRTUAL_START)

/* 16K */
#define CPU_STACK_SHIFT         14
#define CPU_STACK_SIZE          (1 << CPU_STACK_SHIFT)

#define XLEN                    64

#define IS_ENABLED(option)      (option != 0)
