#include <sys/sections.h>
#include <asm/mcall.h>
#include <asm/page.h>
#include <asm/pmp.h>
#include <uapi/certikos/elf.h>
#include "proc.h"

noreturn static void user_init(void);

noreturn void main(unsigned int hartid, phys_addr_t dtb)
{
        mcall_init(dtb);
        proc_init();
        user_init();
}

static void user_init(void)
{
        uint64_t pid = PID_IDLE;

        proc_new(pid, pid, ELF_FILE_IDLE, 0, NR_PAGES);


        /* Set previous privilege to S-mode */
        csr_clear(mstatus, SR_MPP);
        csr_set(mstatus, SR_MPP_S);

        /* Set S-mode XLEN to 64 */
        csr_clear(mstatus, SR_SXL);
        csr_set(mstatus, SR_SXL_64);

        csr_clear(mstatus, SR_UXL);
        csr_set(mstatus, SR_UXL_64);

        /* disable counters in S-mode */
        csr_write(mcounteren, 0);

        /* delegate most exception handling to S-mode */
        csr_write(medeleg, EDEL_BREAKPOINT | EDEL_ECALL_U |
                EDEL_INST_MISALIGNED | EDEL_INST_PAGE_FAULT |
                EDEL_LOAD_MISALIGNED | EDEL_LOAD_PAGE_FAULT |
                EDEL_STORE_MISALIGNED | EDEL_STORE_PAGE_FAULT);

        /* disable interrupts in S-mode */
        csr_write(mideleg, 0);

        /* default to paging off */
        csr_write(satp, SATP_MODE_BARE);

        /* RWX process */
        pmpcfg_write(pmp0cfg, PMPCFG_A_OFF);
        pmpcfg_write(pmp1cfg, PMPCFG_A_TOR | PMPCFG_R | PMPCFG_W | PMPCFG_X);

        /* RX initrd */
        pmpcfg_write(pmp2cfg, PMPCFG_A_OFF);
        pmpcfg_write(pmp3cfg, PMPCFG_A_TOR | PMPCFG_R | PMPCFG_X);

        pmpaddr_write(pmpaddr2, (uintptr_t) _payload_start);
        pmpaddr_write(pmpaddr3, (uintptr_t) _payload_end);

        proc_switch(pid);
}
