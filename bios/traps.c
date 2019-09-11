#include <asm/csr.h>
#include <asm/mcall.h>
#include <asm/ptrace.h>
#include <asm/sbi.h>
#include <sys/console.h>

void show_sys_regs(void)
{
        pr_info("mcause  : " REG_FMT "\n", csr_read(mcause));
        pr_info("mtval   : " REG_FMT "\n", csr_read(mtval));
        pr_info("mepc    : " REG_FMT "\n", csr_read(mepc));
        pr_info("mstatus : " REG_FMT "\n", csr_read(mstatus));
}
