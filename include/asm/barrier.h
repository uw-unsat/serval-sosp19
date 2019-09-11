#pragma once

#define RISCV_FENCE(p, s) \
        __asm__ __volatile__("fence " #p "," #s : : : "memory")

static inline void memory_barrier(void)
{
        RISCV_FENCE(rw, rw);
}

static inline void memory_load_barrier(void)
{
        RISCV_FENCE(r, r);
}

static inline void memory_acquire_barrier(void)
{
        RISCV_FENCE(r, rw);
}

static inline void memory_release_barrier(void)
{
        RISCV_FENCE(rw, w);
}
