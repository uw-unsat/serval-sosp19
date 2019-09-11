#pragma once

#include <asm/ptrace.h>
#include <sys/types.h>

static inline void cpu_relax(void)
{
        barrier();
}

static inline void wait_for_interrupt(void)
{
        asm volatile("wfi");
}
