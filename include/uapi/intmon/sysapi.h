#pragma once

#include "syscalls.h"

enum tlb_type {
        TLB_FREE = 0,
        TLB_PGD,
        TLB_PMD,
        TLB_PTE,
};

long sys_get_shadow_size(void);
long sys_get_region_size(void);
long sys_approve(unsigned long region, unsigned long start_pfn, unsigned long end_pfn);
long sys_revoke(unsigned long region);
long sys_load_pgd(unsigned long pgd_page);
long sys_reset_tlb(unsigned long page, unsigned long type);
long sys_set_pgd_next(unsigned long pgd_page, unsigned long index, unsigned long pmd_page);
long sys_set_pmd_next(unsigned long pmd_page, unsigned long index, unsigned long pte_page);
long sys_set_pte_leaf(unsigned long pte_page, unsigned long index, unsigned long pfn, unsigned long prot);
long sys_clear_pgd_next(unsigned long pgd_page, unsigned long index, unsigned long pmd_page);
long sys_clear_pmd_next(unsigned long pmd_page, unsigned long index, unsigned long pte_page);
long sys_clear_pte_leaf(unsigned long page, unsigned long index);
