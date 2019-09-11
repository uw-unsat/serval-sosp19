#include <asm/csr.h>
#include <asm/pgtable.h>
#include <asm/tlbflush.h>
#include "user.h"

/*  assign -1 to make sure then are not in bss */
static long avail_quota = -1;
static intptr_t alloc_next = -1;

/* maintain quota in user space */
long get_quota(void)
{
        assert(avail_quota >= 0);
        return avail_quota;
}

long spawn(size_t fileid, size_t quota)
{
        static long next_pid = -1;
        long pid, r;

        /* first time */
        if (next_pid < 0)
                next_pid = sys_getpid() * NR_CHILDREN;

        pid = next_pid;
        next_pid++;

        r = sys_spawn(fileid, quota, pid);
        return (r < 0) ? r : pid;
}

static void *boot_alloc(void)
{
        void *result = (void *)alloc_next;

        assert(avail_quota > 0);
        alloc_next += SZ_4K;
        avail_quota -= 1;
        return result;
}

static void vm_map(pgd_t *pgd, uintptr_t va, uintptr_t pa)
{
        unsigned long entry;
        pmd_t *pmd;
        pte_t *pte;

        assert(!(va % SZ_4K));
        assert(!(pa % SZ_4K));

        entry = pgd_val(pgd[pgd_index(va)]);
        if (!entry) {
                pmd = boot_alloc();
                pgd[pgd_index(va)] = pfn_pgd((uintptr_t)pmd / SZ_4K, __pgprot(_PAGE_TABLE));
        } else {
                pmd = (void *)((entry >> _PAGE_PFN_SHIFT) * SZ_4K);
        }

        entry = pmd_val(pmd[pmd_index(va)]);
        if (!entry) {
                pte = boot_alloc();
                pmd[pmd_index(va)] = pfn_pmd((uintptr_t)pte / SZ_4K, __pgprot(_PAGE_TABLE));
        } else {
                pte = (void *)((entry >> _PAGE_PFN_SHIFT) * SZ_4K);
        }

        entry = pte_val(pte[pte_index(va)]);
        assert(!entry);
        pte[pte_index(va)] = pfn_pte(pa / SZ_4K, PAGE_KERNEL_EXEC);
        local_flush_tlb_all();
}

void lib_setup(uintptr_t phys_start, uintptr_t phys_mid, uintptr_t phys_end)
{
        pgd_t *pgd;
        uintptr_t va, pa;

        assert(!(phys_start % SZ_4K));
        assert(!(phys_end % SZ_4K));
        phys_mid = roundup(phys_mid, SZ_4K);
        assert(phys_mid >= phys_start);
        assert(phys_mid <= phys_end);
        avail_quota = (phys_end - phys_mid) / SZ_4K;
        alloc_next = phys_mid;

        printf("setup: %lx %lx %lx\n", phys_start, phys_mid, phys_end);
        pgd = boot_alloc();

        /*
         * Create an identity mapping for [phys_start, phys_end) for the
         * page-fault handling later.  We don't map a 1G superpage as it
         * doesn't work well with PMP on HiFive.
         */
        for (pa = phys_start; pa < phys_end; pa += SZ_4K)
                vm_map(pgd, pa, pa);

        /* map code/data */
        for (va = KERNEL_VIRTUAL_START, pa = phys_start; pa < phys_mid; va += SZ_4K, pa += SZ_4K)
                vm_map(pgd, va, pa);

        csr_write(satp, ((uintptr_t)pgd / SZ_4K) | SATP_MODE_SV39);
        local_flush_tlb_all();
}

static void do_page_fault(void)
{
        pgd_t *pgd = (pgd_t *)(uintptr_t)((csr_read(satp) & SATP_PPN) * SZ_4K);
        uintptr_t va = rounddown(csr_read(stval), SZ_4K);
        uintptr_t pa = (uintptr_t)boot_alloc();

        vm_map(pgd, va, pa);
}

void do_supervisor_trap(struct pt_regs *regs)
{
        static int inprogress = 1;
        unsigned long scause;

        /* no reentry */
        assert(inprogress);
        inprogress = 0;

        scause = csr_read(scause);

        switch (scause) {
        default:
                printf("unknown scause: %ld\n", scause);
                assert(false);
                break;
        case EXC_LOAD_PAGE_FAULT:
        case EXC_STORE_PAGE_FAULT:
                do_page_fault();
                break;
        }

        inprogress = 1;
}
