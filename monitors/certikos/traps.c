#include <asm/csr.h>
#include <asm/mcall.h>
#include <asm/sbi.h>
#include <asm/ptrace.h>
#include <sys/errno.h>
#include <asm/pmp.h>
#include <sys/string.h>
#include <uapi/certikos/syscalls.h>
#include "proc.h"

long sys_get_quota(void)
{
        struct proc *proc;

        proc = proc_current();
        return proc->upper - proc->lower;
}

long sys_spawn(uint64_t fileid, uint64_t quota, uint64_t pid)
{
        struct proc *proc;
        uint64_t upper;

        proc = proc_current();

        /* is quota too large? */
        if (proc->upper - proc->lower < quota)
                return -EINVAL;
        /* is pid valid? */
        if (!is_pid_valid(pid))
                return -EINVAL;
        pid = array_index_nospec(pid, NR_PROCS);
        /* does the current process have the permission to allocate this pid? */
        if (!is_pid_owned_by_current(pid))
                return -EINVAL;
        /* has pid been allocated? */
        if (!is_proc_free(pid))
                return -EINVAL;

        /* child takes this new top */
        upper = proc->upper;

        /* take quota off the current process */
        proc->upper -= quota;

        proc_new(pid, proc->next, fileid, proc->upper, upper);

        proc->next = pid;


#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM)
        /* switch pmp & flush tlb */
        pmpaddr_write(pmpaddr0, (uintptr_t)(&pages[proc->lower]));
        pmpaddr_write(pmpaddr1, (uintptr_t)(&pages[proc->upper]));
        local_flush_tlb_all();
#endif

        return 0;
}

long do_yield(void)
{
        struct proc *proc;

        proc = proc_current();
        current_pid = proc->next;

        return 0;
}

/*
 * This function consists of three actions under different domains:
 * - saving registers, under the current pid;
 * - scheduling the next process, under the scheduler;
 * - resuming the next process, under the next pid.
 */
long sys_yield(struct pt_regs *regs)
{
        struct proc *proc;

        proc = proc_current();

        /* save registers */
        copy_pt_regs(&proc->cpu, regs);
        proc_save_csrs(proc);

        do_yield();

        proc_switch(current_pid);
        return 0;
}

long sys_getpid(void)
{
        return current_pid;
}

void do_trap_ecall_s(struct pt_regs *regs)
{
        long nr = regs->a7, r = -ENOSYS;

        csr_write(mepc, csr_read(mepc) + 4);

        switch (nr) {
#if IS_ENABLED(CONFIG_VERIFICATION)
        default:
                break;
#else
        default:
                pr_warn("unknown syscall %ld\n", nr);
                break;
        case SBI_FIRST ... SBI_LAST:
                r = do_mcall(regs);
                break;
#endif
        case __NR_get_quota:
                r = sys_get_quota();
                break;
        case __NR_spawn:
                r = sys_spawn(regs->a0, regs->a1, regs->a2);
                break;
        case __NR_yield:
                r = sys_yield(regs);
                break;
        case __NR_getpid:
                r = sys_getpid();
                break;
        }

        regs->a0 = r;
}
