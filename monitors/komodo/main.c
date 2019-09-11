#include <sys/sections.h>
#include <sys/string.h>
#include <asm/mcall.h>
#include <asm/page.h>
#include <asm/pmp.h>
#include <asm/csr.h>
#include <uapi/komodo/memregions.h>
#include "monitor.h"

static noreturn void supervisor_init(unsigned int hartid, phys_addr_t dtb);
extern void init_monitor(void);

noreturn void main(unsigned int hartid, phys_addr_t dtb)
{
        mcall_init(dtb);
        init_monitor();
        supervisor_init(hartid, kernel_dtb);
}

static void pmp_init(void)
{
        extern char secure_pages[];
        const uint64_t rwx = PMPCFG_R | PMPCFG_W | PMPCFG_X;
        phys_addr_t pa_insecure_start, pa_insecure_end,
                    pa_secure_start, pa_secure_end;

        pa_insecure_start = (phys_addr_t) _payload_start;
        pa_insecure_end = pa_insecure_start + KOM_INSECURE_RESERVE;
        pa_secure_start = (phys_addr_t) secure_pages;
        pa_secure_end = pa_secure_start + KOM_SECURE_RESERVE;

        /* allow insecure regions */
        pmpaddr_write(pmpaddr2, pa_insecure_start);
        pmpaddr_write(pmpaddr3, pa_insecure_end);
        pmpcfg_write(pmp2cfg, PMPCFG_A_OFF);
        pmpcfg_write(pmp3cfg, PMPCFG_A_TOR | rwx);

        /* allow secure pages only for enclaves */
        pmpaddr_write(pmpaddr4, pa_secure_start);
        pmpaddr_write(pmpaddr5, pa_secure_end);
        pmpcfg_write(pmp4cfg, PMPCFG_A_OFF);
        pmpcfg_write(pmp5cfg, PMPCFG_A_TOR);
}

static void noinline supervisor_init(unsigned int hartid, phys_addr_t dtb)
{
        struct pt_regs regs;
#if IS_ENABLED(CONFIG_VERIFICATION)
        regs.a0 = hartid;
        regs.a1 = dtb;
#else
        regs = (struct pt_regs) {
                .a0 = hartid,
                .a1 = dtb,
        };
#endif

        pmp_init();

        /* prepare for S-mode (interrupts disabled in M-mode) */
        csr_write(mstatus, SR_MPP_S);

        /* enable counters for S-mode */
        csr_write(mcounteren, ~UINT32_C(0));

        /* delegate most exception handling to S-mode */
        csr_write(medeleg, EDEL_BREAKPOINT | EDEL_ECALL_U |
                EDEL_INST_MISALIGNED | EDEL_INST_PAGE_FAULT |
                EDEL_LOAD_MISALIGNED | EDEL_LOAD_PAGE_FAULT |
                EDEL_STORE_MISALIGNED | EDEL_STORE_PAGE_FAULT);
        /* NB: spike and QEMU behave differently if delegating S-mode ecalls */

        /* delegate interrupt handling to S-mode */
        csr_write(mideleg, IDEL_SOFT_S | IDEL_TIMER_S | IDEL_EXT_S);

        /* jump directly to payload */
        csr_write(mepc, _payload_start);

        mret_with_regs(&regs);
}
