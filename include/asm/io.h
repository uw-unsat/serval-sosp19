#pragma once

#include <sys/types.h>

#define __iomem

static inline uint8_t __raw_readb(const volatile void __iomem *addr)
{
        uint8_t val;

        asm volatile("lb %0, 0(%1)" : "=r" (val) : "r" (addr));
        return val;
}

static inline uint16_t __raw_readw(const volatile void __iomem *addr)
{
        uint16_t val;

        asm volatile("lh %0, 0(%1)" : "=r" (val) : "r" (addr));
        return val;
}

static inline uint32_t __raw_readl(const volatile void __iomem *addr)
{
        uint32_t val;

        asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
        return val;
}

static inline uint64_t __raw_readq(const volatile void __iomem *addr)
{
        uint64_t val;

        asm volatile("ld %0, 0(%1)" : "=r" (val) : "r" (addr));
        return val;
}

static inline void __raw_writeb(uint8_t val, volatile void __iomem *addr)
{
        asm volatile("sb %0, 0(%1)" : : "r" (val), "r" (addr));
}

static inline void __raw_writew(uint16_t val, volatile void __iomem *addr)
{
        asm volatile("sh %0, 0(%1)" : : "r" (val), "r" (addr));
}

static inline void __raw_writel(uint32_t val, volatile void __iomem *addr)
{
        asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
}

static inline void __raw_writeq(uint64_t val, volatile void __iomem *addr)
{
        asm volatile("sd %0, 0(%1)" : : "r" (val), "r" (addr));
}

/*
 * Unordered I/O memory access primitives.  These are even more relaxed than
 * the relaxed versions, as they don't even order accesses between successive
 * operations to the I/O regions.
 */
#define readb_cpu       __raw_readb
#define readw_cpu       __raw_readw
#define readl_cpu       __raw_readl
#define readq_cpu       __raw_readq

#define writeb_cpu      __raw_writeb
#define writew_cpu      __raw_writew
#define writel_cpu      __raw_writel
#define writeq_cpu      __raw_writeq

/*
 * I/O memory access primitives. Reads are ordered relative to any
 * following Normal memory access. Writes are ordered relative to any prior
 * Normal memory access.  The memory barriers here are necessary as RISC-V
 * doesn't define any ordering between the memory space and the I/O space.
 */
#define __io_br()       do {} while (0)
#define __io_ar()       asm volatile("fence i,r" : : : "memory");
#define __io_bw()       asm volatile("fence w,o" : : : "memory");
#define __io_aw()       do {} while (0)

#define readb(c)        ({ uint8_t  __v; __io_br(); __v = readb_cpu(c); __io_ar(); __v; })
#define readw(c)        ({ uint16_t __v; __io_br(); __v = readw_cpu(c); __io_ar(); __v; })
#define readl(c)        ({ uint32_t __v; __io_br(); __v = readl_cpu(c); __io_ar(); __v; })
#define readq(c)        ({ uint64_t __v; __io_br(); __v = readq_cpu(c); __io_ar(); __v; })

#define writeb(v,c)     ({ __io_bw(); writeb_cpu((v),(c)); __io_aw(); })
#define writew(v,c)     ({ __io_bw(); writew_cpu((v),(c)); __io_aw(); })
#define writel(v,c)     ({ __io_bw(); writel_cpu((v),(c)); __io_aw(); })
#define writeq(v,c)     ({ __io_bw(); writeq_cpu((v),(c)); __io_aw(); })
