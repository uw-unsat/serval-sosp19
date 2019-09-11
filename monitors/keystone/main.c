#include <sys/sections.h>
#include <asm/csr.h>
#include <asm/mcall.h>
#include <asm/pmp.h>
#include <asm/page.h>
#include "pmp.h"
#include "enclave.h"

static void pmp_init(void);
noreturn static void supervisor_init(unsigned int hartid, phys_addr_t dtb);

noreturn void main(unsigned int hartid, phys_addr_t dtb)
{
        mcall_init(dtb);
        init_enclave();

        pmp_init();
        supervisor_init(hartid, kernel_dtb);
}


static void pmp_init(void)
{
#if !IS_ENABLED(CONFIG_VERIFICATION)
        /* take the last region to enable "everything else" (i.e., not an enclave and not the monitor) */
        remap_os_region();

        local_flush_tlb_all();
#endif /* !IS_ENABLED(CONFIG_VERIFICATION) */
}


static void supervisor_init(unsigned int hartid, phys_addr_t dtb)
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

        /* Set previous privilege to S-mode */
        csr_clear(mstatus, SR_MPP);
        csr_set(mstatus, SR_MPP_S);

        /* Set S-mode XLEN to 64 */
        csr_clear(mstatus, SR_SXL);
        csr_set(mstatus, SR_SXL_64);

        csr_clear(mstatus, SR_UXL);
        csr_set(mstatus, SR_UXL_64);

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
