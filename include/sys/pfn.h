/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <asm/page.h>

typedef struct {
        uint64_t val;
} pfn_t;

#define PFN_ALIGN(x)    (((unsigned long)(x) + (PAGE_SIZE - 1)) & PAGE_MASK)
#define PFN_UP(x)       (((x) + PAGE_SIZE-1) >> PAGE_SHIFT)
#define PFN_DOWN(x)     ((x) >> PAGE_SHIFT)
#define PFN_PHYS(x)     ((phys_addr_t)(x) << PAGE_SHIFT)
#define PHYS_PFN(x)     ((unsigned long)((x) >> PAGE_SHIFT))

static inline pfn_t pfn_to_pfn_t(unsigned long pfn)
{
        pfn_t pfn_t = { .val = pfn };

        return pfn_t;
}

static inline unsigned long pfn_t_to_pfn(pfn_t pfn)
{
        return pfn.val;
}

static inline phys_addr_t pfn_t_to_phys(pfn_t pfn)
{
        return PFN_PHYS(pfn_t_to_pfn(pfn));
}

static inline void *pfn_t_to_virt(pfn_t pfn)
{
        return __va(pfn_t_to_phys(pfn));
}

#define virt_to_pfn(vaddr)      (__pa(vaddr) >> PAGE_SHIFT)
#define pfn_to_virt(pfn)        __va((pfn) << PAGE_SHIFT)
