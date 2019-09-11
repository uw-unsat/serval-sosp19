#include <asm/csr.h>
#include <asm/mcall.h>
#include <asm/ptrace.h>
#include <asm/sbi.h>
#include "monitor.h"

static void do_smc_calls(struct pt_regs *regs)
{
        long nr = regs->a7, r = -ENOSYS;
        unsigned long pc;

        pc = csr_read(mepc) + 4;
        csr_write(mepc, pc);

        switch (nr) {
        default:
                break;
#if !IS_ENABLED(CONFIG_VERIFICATION)
        case SBI_FIRST ... SBI_LAST:
                r = do_mcall(regs);
                break;
#endif
        case KOM_SMC_QUERY:
                r = kom_smc_query();
                break;
        case KOM_SMC_GETPHYSPAGES:
                r = kom_smc_get_phys_pages();
                break;
        case KOM_SMC_INIT_ADDRSPACE:
                r = kom_smc_init_addrspace(regs->a0, regs->a1);
                break;
        case KOM_SMC_INIT_DISPATCHER:
                r = kom_smc_init_dispatcher(regs->a0, regs->a1, regs->a2);
                break;
        case KOM_SMC_INIT_L2PTABLE:
                r = kom_smc_init_l2ptable(regs->a0, regs->a1, regs->a2);
                break;
        case KOM_SMC_INIT_L3PTABLE:
                r = kom_smc_init_l3ptable(regs->a0, regs->a1, regs->a2);
                break;
        case KOM_SMC_MAP_SECURE:
                r = kom_smc_map_secure(regs->a0, regs->a1, regs->a2, regs->a3, regs->a4);
                break;
        case KOM_SMC_MAP_INSECURE:
                r = kom_smc_map_insecure(regs->a0, regs->a1, regs->a2, regs->a3);
                break;
        case KOM_SMC_REMOVE:
                r = kom_smc_remove(regs->a0);
                break;
        case KOM_SMC_FINALISE:
                r = kom_smc_finalise(regs->a0);
                break;
        case KOM_SMC_ENTER:
                r = kom_smc_enter(regs->a0, regs->a1, regs->a2, regs->a3);
                break;
        case KOM_SMC_RESUME:
                r = kom_smc_resume(regs->a0);
                break;
        case KOM_SMC_STOP:
                r = kom_smc_stop(regs->a0);
                break;
        }

        regs->a0 = r;
}

static void do_svc_calls(struct pt_regs *regs)
{
        long nr = regs->a7, r = -ENOSYS;
        unsigned long pc;

        pc = csr_read(mepc) + 4;
        csr_write(mepc, pc);

        switch (nr) {
        default:
                break;
        case KOM_SVC_EXIT:
                r = kom_svc_exit(regs->a0);
                break;
        }

        regs->a0 = r;
}

void do_trap_ecall_s(struct pt_regs *regs)
{
#if !IS_ENABLED(CONFIG_VERIFICATION)
        unsigned long mstatus = csr_read(mstatus);

        if ((mstatus & SR_MPP) == SR_MPP_M)
                die(regs, "trap from M-mode\n");

        if ((mstatus & SR_MPP) == SR_MPP_U)
                die(regs, "trap from U-mode\n");
#endif

        if (enclave_mode)
                do_svc_calls(regs);
        else
                do_smc_calls(regs);
}

void do_trap(struct pt_regs *regs, unsigned long cause)
{
        switch (cause) {
        case EXC_ECALL_S:
                do_trap_ecall_s(regs);
                break;
        default:
                if (enclave_mode)
                        kom_handle_trap(cause);
                break;
        }
}
