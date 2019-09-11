#pragma once

#include <asm/page.h>
#include <asm/pgtable-bits.h>
#include <io/const.h>

#define PGD_SHIFT       30
#define PGD_SIZE        (_AC(1, UL) << PGD_SHIFT)
#define PGD_MASK        (~(PGD_SIZE - 1))

#define PMD_SHIFT       21
#define PMD_SIZE        (_AC(1, UL) << PMD_SHIFT)
#define PMD_MASK        (~(PMD_SIZE - 1))

#define PTE_SHIFT       12
#define PTE_SIZE        (_AC(1, UL) << PTE_SHIFT)
#define PTE_MASK        (~(PTE_SIZE - 1))

#ifndef __ASSEMBLER__

/*
 * Use struct definitions to apply C type checking
 */

#include <sys/pfn.h>

/* Page Global Directory entry */
typedef struct {
        unsigned long pgd;
} pgd_t;

/* Page Middle Directory entry */
typedef struct {
        unsigned long pmd;
} pmd_t;

/* Page Table entry */
typedef struct {
        unsigned long pte;
} pte_t;

typedef struct {
        unsigned long pgprot;
} pgprot_t;

#define pgd_val(x)      ((x).pgd)
#define pmd_val(x)      ((x).pmd)
#define pte_val(x)      ((x).pte)
#define pgprot_val(x)   ((x).pgprot)

#define __pgd(x)        ((pgd_t) { (x) })
#define __pmd(x)        ((pmd_t) { (x) })
#define __pte(x)        ((pte_t) { (x) })
#define __pgprot(x)     ((pgprot_t) { (x) })

#define PTRS_PER_PGD    (PAGE_SIZE / sizeof(pgd_t))
#define PTRS_PER_PMD    (PAGE_SIZE / sizeof(pmd_t))
#define PTRS_PER_PTE    (PAGE_SIZE / sizeof(pte_t))

#define pgd_index(addr) (((addr) >> PGD_SHIFT) & (PTRS_PER_PGD - 1))
#define pmd_index(addr) (((addr) >> PMD_SHIFT) & (PTRS_PER_PMD - 1))
#define pte_index(addr) (((addr) >> PAGE_SHIFT) & (PTRS_PER_PTE - 1))

#define _PAGE_KERNEL            (_PAGE_READ \
                                | _PAGE_WRITE \
                                | _PAGE_PRESENT \
                                | _PAGE_ACCESSED \
                                | _PAGE_DIRTY)

#define PAGE_KERNEL             __pgprot(_PAGE_KERNEL)
#define PAGE_KERNEL_EXEC        __pgprot(_PAGE_KERNEL | _PAGE_EXEC)

static inline pgd_t pfn_pgd(unsigned long pfn, pgprot_t prot)
{
        return __pgd((pfn << _PAGE_PFN_SHIFT) | pgprot_val(prot));
}

static inline pmd_t pfn_pmd(unsigned long pfn, pgprot_t prot)
{
        return __pmd((pfn << _PAGE_PFN_SHIFT) | pgprot_val(prot));
}

static inline pte_t pfn_pte(unsigned long pfn, pgprot_t prot)
{
        return __pte((pfn << _PAGE_PFN_SHIFT) | pgprot_val(prot));
}

static inline unsigned long pgd_pfn(pgd_t pgd)
{
        return (pgd_val(pgd) >> _PAGE_PFN_SHIFT);
}

static inline unsigned long pmd_pfn(pmd_t pmd)
{
        return (pmd_val(pmd) >> _PAGE_PFN_SHIFT);
}

static inline unsigned long pte_pfn(pte_t pte)
{
        return (pte_val(pte) >> _PAGE_PFN_SHIFT);
}

static inline int pgd_present(pgd_t pgd)
{
        return (pgd_val(pgd) & _PAGE_PRESENT);
}

static inline int pmd_present(pmd_t pmd)
{
        return (pmd_val(pmd) & _PAGE_PRESENT);
}

static inline int pte_present(pte_t pte)
{
        return (pte_val(pte) & _PAGE_PRESENT);
}

#endif
