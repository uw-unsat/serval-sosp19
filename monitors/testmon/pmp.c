#include <asm/pgtable.h>
#include <asm/pmp.h>
#include "test.h"

static int set_pmpcfg(struct test *test, unsigned long start, unsigned long end)
{
        unsigned long i;

        for (i = start; i < end; ++i) {
                unsigned long cfg0, cfg1;

                cfg0 = pmpcfg_read(i);
                pmpcfg_write(i, cfg0 | PMPCFG_RWX);
                cfg1 = pmpcfg_read(i);
                pmpcfg_write(i, cfg0);
                ASSERT_EQ(PMPCFG_RWX, cfg1 & PMPCFG_RWX);
        }

        return 0;
}

static int set_pmpcfg0(struct test *test)
{
        return set_pmpcfg(test, 0, 8);
}

#if 0
static int set_pmpcfg2(struct test *test)
{
        return set_pmpcfg(test, 8, 16);
}
#endif

static uint8_t test_data[2 * SZ_4K] __aligned(SZ_4K);

__naked __aligned(SZ_4K)
static void test_empty(void)
{
        asm volatile (
                "1: \n\t"
                "li a7, 8 \n\t"
                "ecall \n\t"
                "wfi \n\t"
                "j 1b \n\t"
                : : : "memory"
        );
}

__naked __aligned(SZ_4K)
static void test_write_0(void)
{
        asm volatile (
                "1: \n\t"
                "sw x0, 0(%0) \n\t"
                /* end of region */
                "lw x0, 28(%0) \n\t"
                /* out of bounds */
                "lw x0, 32(%0) \n\t"
                "li a7, 8 \n\t"
                "ecall \n\t"
                "wfi \n\t"
                "j 1b \n\t"
                : : "r" (test_data)
                : "memory"
        );
}

static int write_0(struct test *test)
{
        struct pt_regs regs = { 0 };
        unsigned long cfg0, addr0, addr1;

        /* delegation off */
        csr_write(medeleg, 0);
        csr_write(mideleg, 0);
        /* paging off */
        csr_write(satp, SATP_MODE_BARE);

        csr_write(mstatus, SR_MPP_S);

        cfg0 = csr_read(pmpcfg0);
        addr0 = pmpaddr_read(pmpaddr0);
        addr1 = pmpaddr_read(pmpaddr1);

        /* clear PMP configurations */
        csr_write(pmpcfg0, 0);
        pmpcfg_write(pmp0cfg, PMPCFG_A_NAPOT | PMPCFG_X);
        pmpcfg_write(pmp1cfg, PMPCFG_A_NAPOT | PMPCFG_R | PMPCFG_W);
        pmpaddr_write(pmpaddr0, (((uintptr_t)test_write_0) | (SZ_4K - 1)));
        pmpaddr_write(pmpaddr1, (((uintptr_t)test_data) | ((32 - 1) >> 1)));
        local_flush_tlb_all();
        test_run_guest(&regs, test_write_0);

        csr_write(pmpcfg0, cfg0);
        pmpaddr_write(pmpaddr0, addr0);
        pmpaddr_write(pmpaddr1, addr1);

        ASSERT_EQ(EXC_LOAD_ACCESS, csr_read(mcause));
        ASSERT_EQ((uintptr_t)test_data + 32, csr_read(mtval));

        return 0;
}

__naked __aligned(SZ_4K)
static void test_write_performance()
{
        static const uint64_t nr_iter = 8192;

        asm volatile (
                "1: \n\t"

                "sb %0, 0(%0) \n\t"
                "sb %1, 0(%1) \n\t"

                "addi %2, %2, -1\n\t"
                "bnez %2, 1b \n\t"
                "ecall \n\t"
                "j 1b \n\t"
                : : "r" ((uintptr_t) test_data + 0),
                    "r" ((uintptr_t) test_data + SZ_4K),
                    "r" (nr_iter)
                : "memory"
        );
}

/*
 * Run a PMP performance test.
 * pmp_mode:
 *  0 - homogeneous PMP
 *  1 - non-homogeneous PMP
 * paging_mode:
 *  0 - No paging
 *  1 - 4k pages
 * Returns avg number of cycles per iteration
 */
static uint64_t run_pmp_perf_test(int pmp_mode, int paging_mode)
{
        static pgd_t pgd[512] __aligned(SZ_4K);
        static pmd_t pmd[512] __aligned(SZ_4K);
        static pte_t pte[512] __aligned(SZ_4K);
        struct pt_regs regs = { 0 };
        uint64_t before, after;
        uintptr_t code, data;
        size_t pgd_idx, pmd_idx;

        code = (uintptr_t) test_write_performance;
        data = (uintptr_t) test_data;

        /* no delegation */
        csr_write(medeleg, 0);
        csr_write(mideleg, 0);

        csr_write(mcounteren, ~0ul);
        csr_write(scounteren, ~0ul);
        csr_write(mstatus, SR_MPP_S);

        /* Clear existing PMP regions */
        csr_write(pmpcfg0, 0);
        csr_write(pmpcfg2, 0);

        /* Allow access to code */
        pmpcfg_write(pmp2cfg, PMPCFG_A_NAPOT | PMPCFG_X);
        pmpaddr_write(pmpaddr2, (code | (SZ_4K / 2 - 1)));

        switch (pmp_mode) {
        case 0: /* homogeneous PMP */
                pmpcfg_write(pmp0cfg, PMPCFG_A_NAPOT | PMPCFG_W);
                pmpaddr_write(pmpaddr0, (data | (SZ_4K / 2 - 1)));
                pmpcfg_write(pmp1cfg, PMPCFG_A_NAPOT | PMPCFG_W);
                pmpaddr_write(pmpaddr1, ((data + SZ_4K) | (SZ_4K / 2 - 1)));
                break;
        case 1: /* non-homogeneous PMP */
                pmpcfg_write(pmp0cfg, PMPCFG_A_NAPOT | PMPCFG_W);
                pmpaddr_write(pmpaddr0, (data | (8 / 2 - 1)));
                pmpcfg_write(pmp1cfg, PMPCFG_A_NAPOT | PMPCFG_W);
                pmpaddr_write(pmpaddr1, ((data + SZ_4K) | (8 / 2 - 1)));
                break;
        default:
                BUG();
        }

        switch (paging_mode) {
        case 0:
                /* No paging */
                csr_write(satp, SATP_MODE_BARE);
                break;
        case 1: /* Identity paging: 4K pages */

                /* Need to allow access to page tables themselves in PMP */
                pmpcfg_write(pmp3cfg, PMPCFG_A_NAPOT | PMPCFG_R);
                pmpaddr_write(pmpaddr3, ((uintptr_t) pgd | (SZ_4K / 2 - 1)));
                pmpcfg_write(pmp4cfg, PMPCFG_A_NAPOT | PMPCFG_R);
                pmpaddr_write(pmpaddr4, ((uintptr_t) pmd | (SZ_4K / 2 - 1)));
                pmpcfg_write(pmp5cfg, PMPCFG_A_NAPOT | PMPCFG_R);
                pmpaddr_write(pmpaddr5, ((uintptr_t) pte | (SZ_4K / 2 - 1)));

                pgd_idx = pgd_index(code);
                pmd_idx = pmd_index(code);

                ASSERT_EQ(pgd_idx, pgd_index(data));
                ASSERT_EQ(pmd_idx, pmd_index(data));

                pgd[pgd_idx] = pfn_pgd((uintptr_t) pmd / SZ_4K, __pgprot(_PAGE_TABLE));
                pmd[pmd_idx] = pfn_pmd((uintptr_t) pte / SZ_4K, __pgprot(_PAGE_TABLE));

                pte[pte_index(code)] =
                  pfn_pte(code / SZ_4K, PAGE_KERNEL_EXEC);
                pte[pte_index(data)] =
                  pfn_pte(data / SZ_4K, PAGE_KERNEL_EXEC);
                pte[pte_index(data) + 1] =
                  pfn_pte((data / SZ_4K) + 1, PAGE_KERNEL_EXEC);

                csr_write(satp, SATP_MODE_SV39 | PHYS_PFN((uintptr_t)pgd));
                break;

        default:
                BUG();
        }

        /* Count data TLB misses */
        csr_write(mhpmevent3, 2 | (1 << 12));
        csr_write(mhpmcounter3, 0);

        local_flush_tlb_all();
        asm volatile("fence iorw, iorw");
        before = csr_read(mhpmcounter3);
        test_run_guest(&regs, test_write_performance);
        after = csr_read(mhpmcounter3);

        ASSERT_EQ(EXC_ECALL_S, csr_read(mcause));

        csr_write(pmpcfg0, 0);
        csr_write(satp, SATP_MODE_BARE);

        return (after - before);
}

static int pmp_performance_test(struct test *test)
{
        pr_info("i: \n"
                "  0 homogeneous PMP\n"
                "  1 non-homogeneous PMP\n"
                "j: \n"
                "  0 no paging\n"
                "  1 4K pages\n");

        for (int i = 0; i <= 1; ++i) {
                for (int j = 0; j <= 1; ++j) {
                        uint64_t total = 0;
                        for (int iter = 0; iter < 32; ++iter) {
                                total += run_pmp_perf_test(i, j);
                        }
                        pr_info("run_pmp_perf_test(i = %d, j = %d) = %lu\n", i, j, total / 32);
                }
        }

        return 0;
}

static int exec_superpage(struct test *test)
{
        struct pt_regs regs = { 0 };
        unsigned long cfg0, addr0, addr1;
        static pgd_t pgd[512] __aligned(SZ_4K);
        uintptr_t addr = (uintptr_t)test_empty;
        size_t i;

        /* delegation off */
        csr_write(medeleg, 0);
        csr_write(mideleg, 0);
        /* 1G identity mapping */
        for (i = 0; i < ARRAY_SIZE(pgd); ++i)
                pgd[i] = pfn_pgd(PHYS_PFN(i * SZ_1G), PAGE_KERNEL_EXEC);
        /* paging on */
        csr_write(satp, SATP_MODE_SV39 | PHYS_PFN((uintptr_t)pgd));

        csr_write(mstatus, SR_MPP_S);

        cfg0 = csr_read(pmpcfg0);
        addr0 = pmpaddr_read(pmpaddr0);
        addr1 = pmpaddr_read(pmpaddr1);

        /* clear PMP configurations */
        csr_write(pmpcfg0, 0);
        pmpcfg_write(pmp0cfg, PMPCFG_A_NAPOT | PMPCFG_X);
        pmpcfg_write(pmp1cfg, PMPCFG_A_NAPOT | PMPCFG_R | PMPCFG_W);
        /* 4K code region */
        pmpaddr_write(pmpaddr0, (addr | (SZ_4K / 2 - 1)));
        /* 4K pgd */
        pmpaddr_write(pmpaddr1, ((uintptr_t)pgd | (SZ_4K / 2 - 1)));
        local_flush_tlb_all();
        test_run_guest(&regs, test_empty);

        csr_write(satp, SATP_MODE_BARE);
        csr_write(pmpcfg0, cfg0);
        pmpaddr_write(pmpaddr0, addr0);
        pmpaddr_write(pmpaddr1, addr1);

        ASSERT_EQ(EXC_ECALL_S, csr_read(mcause));

        return 0;
}

static struct test tests[] = {
        TEST(set_pmpcfg0),
        TEST(write_0),
        TEST(exec_superpage),
        TEST(pmp_performance_test),
};

struct test_suite pmp_test = {
        .name = "pmp_test",
        .count = ARRAY_SIZE(tests),
        .tests = tests,
};
