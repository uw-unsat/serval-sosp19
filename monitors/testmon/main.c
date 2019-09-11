#define pr_fmt(fmt)     "testmon: " fmt

#include <asm/mcall.h>
#include <asm/page.h>
#include <asm/pmp.h>
#include <asm/tlbflush.h>
#include <sys/of.h>
#include "test.h"

extern void cpu_info(void);

noreturn void main(unsigned int hartid, phys_addr_t dtb)
{
        struct test_suite **suite;

        mcall_init(dtb);
        cpu_info();

        pmpcfg_write(0, PMPCFG_A_NAPOT | PMPCFG_R | PMPCFG_W | PMPCFG_X);
        pmpaddr_write(pmpaddr0, ~0x0ul);
        local_flush_tlb_all();

        for (suite = suites_start; suite < suites_end; ++suite)
                test_register(*suite);


        test_run();

        mcall_shutdown();
}
