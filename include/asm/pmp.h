#pragma once

#include <asm/csr.h>
#include <asm/tlbflush.h>
#include <sys/printk.h>

#define pmpaddr_read(reg)               (csr_read(reg) << 2)
#define pmpaddr_write(reg, val)         csr_write(reg, ((val) >> 2))

enum pmpcfg {
        pmp0cfg = 0,
        pmp1cfg,
        pmp2cfg,
        pmp3cfg,
        pmp4cfg,
        pmp5cfg,
        pmp6cfg,
        pmp7cfg,
     /* pmp8cfg,
        pmp9cfg,
        pmp10cfg,
        pmp11cfg,
        pmp12cfg,
        pmp13cfg,
        pmp14cfg,
        pmp15cfg, */
        NR_PMP_ENTRIES,
};

static inline unsigned long pmpcfg_read(enum pmpcfg nr)
{
        unsigned long r, shift = (nr % 8) * 8;

        r = (nr < 8) ? csr_read(pmpcfg0) : csr_read(pmpcfg2);
        return (r >> shift) & 0xff;
}

static inline void pmpcfg_write(enum pmpcfg nr, unsigned long value)
{
        unsigned long shift = (nr % 8) * 8;
        unsigned long mask = 0xffL << shift;

        if (nr < 8) {
                csr_clear(pmpcfg0, mask);
                csr_set(pmpcfg0, value << shift);
        } else {
                csr_clear(pmpcfg2, mask);
                csr_set(pmpcfg2, value << shift);
        }

        if (pmpcfg_read(nr) != value)
                pr_err("pmpcfg_write: %d 0x%lx\n", nr, value);
}
