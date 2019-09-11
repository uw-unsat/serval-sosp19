#include <sys/errno.h>
#include <sys/printk.h>
#include <asm/csr.h>
#include <asm/mcall.h>
#include <asm/ptrace.h>
#include <asm/sbi.h>
#include <sys/bug.h>
#include <sys/string.h>
#include <uapi/keystone/syscalls.h>
#include "enclave.h"

void do_trap_ecall_s(struct pt_regs *regs)
{
        uint64_t nr = regs->a7, r = 0;
        uint64_t a0 = regs->a0, a1 = regs->a1;
        uint64_t a2 = regs->a2, a3 = regs->a3;
        uint64_t a4 = regs->a4, a5 = regs->a5;

        switch (nr) {
        default:
                r = -ENOSYS;
                break;
        case SBI_FIRST ... SBI_LAST:
                r = do_mcall(regs);
                break;
        case __NR_create_enclave:
                r = sys_create_enclave(a0, a1, a2, a3, a4, a5);
                break;

        case __NR_destroy_enclave:
                r = sys_destroy_enclave(a0);
                break;

        case __NR_run_enclave:
                r = sys_run_enclave(a0);
                break;

        case __NR_exit_enclave:
                r = sys_exit_enclave();
                break;

        case __NR_resume_enclave:
                r = sys_resume_enclave(a0);
                break;

        }

        regs->a0 = r;
        if (nr != __NR_run_enclave)
                csr_write(mepc, csr_read(mepc) + 4);
}
