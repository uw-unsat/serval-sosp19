#include <asm/csr.h>
#include <asm/ptrace.h>
#include <sys/types.h>

void show_gp_regs(struct pt_regs *regs)
{
        pr_info("zero: " REG_FMT " ra : " REG_FMT " sp : " REG_FMT " gp : " REG_FMT "\n",
                0UL, regs->ra, regs->sp, regs->gp);
        pr_info(" tp : " REG_FMT " t0 : " REG_FMT " t1 : " REG_FMT " t2 : " REG_FMT "\n",
                regs->tp, regs->t0, regs->t1, regs->t2);
        pr_info(" s0 : " REG_FMT " s1 : " REG_FMT " a0 : " REG_FMT " a1 : " REG_FMT "\n",
                regs->s0, regs->s1, regs->a0, regs->a1);
        pr_info(" a2 : " REG_FMT " a3 : " REG_FMT " a4 : " REG_FMT " a5 : " REG_FMT "\n",
                regs->a2, regs->a3, regs->a4, regs->a5);
        pr_info(" a6 : " REG_FMT " a7 : " REG_FMT " s2 : " REG_FMT " s3 : " REG_FMT "\n",
                regs->a6, regs->a7, regs->s2, regs->s3);
        pr_info(" s4 : " REG_FMT " s5 : " REG_FMT " s6 : " REG_FMT " s7 : " REG_FMT "\n",
                regs->s4, regs->s5, regs->s6, regs->s7);
        pr_info(" s8 : " REG_FMT " s9 : " REG_FMT " s10: " REG_FMT " s11: " REG_FMT "\n",
                regs->s8, regs->s9, regs->s10, regs->s11);
        pr_info(" t3 : " REG_FMT " t4 : " REG_FMT " t5 : " REG_FMT " t6 : " REG_FMT "\n",
                regs->t3, regs->t4, regs->t5, regs->t6);
}

__weak void show_sys_regs(void)
{
        pr_info("scause  : " REG_FMT "\n", csr_read(scause));
        pr_info("stval   : " REG_FMT "\n", csr_read(stval));
        pr_info("sepc    : " REG_FMT "\n", csr_read(sepc));
        pr_info("sstatus : " REG_FMT "\n", csr_read(sstatus));
}

void show_regs(struct pt_regs *regs)
{
        show_gp_regs(regs);
        show_sys_regs();
}

__weak void do_trap_error(struct pt_regs *regs, const char *str)
{
        die(regs, str);
}

#define DO_ERROR_INFO(name, str)                                        \
__weak void name(struct pt_regs *regs)                                  \
{                                                                       \
        do_trap_error(regs, "oops: " str "\n");                         \
}

DO_ERROR_INFO(do_trap_unknown,
        "unknown exception");
DO_ERROR_INFO(do_trap_insn_misaligned,
        "instruction address misaligned");
DO_ERROR_INFO(do_trap_insn_fault,
        "instruction access fault");
DO_ERROR_INFO(do_trap_insn_illegal,
        "illegal instruction");
DO_ERROR_INFO(do_trap_break,
        "breakpoint");
DO_ERROR_INFO(do_trap_load_misaligned,
        "load address misaligned");
DO_ERROR_INFO(do_trap_load_fault,
        "load access fault");
DO_ERROR_INFO(do_trap_store_misaligned,
        "store (or AMO) address misaligned");
DO_ERROR_INFO(do_trap_store_fault,
        "store (or AMO) access fault");
DO_ERROR_INFO(do_trap_ecall_u,
        "environment call from U-mode");
DO_ERROR_INFO(do_trap_ecall_s,
        "environment call from S-mode");
DO_ERROR_INFO(do_trap_ecall_m,
        "environment call from M-mode");
DO_ERROR_INFO(do_interrupt,
        "unknown interrupt");

__weak void do_trap(struct pt_regs *regs, unsigned long cause)
{
        switch (cause) {
        default:
                if (cause & INTR_BIT)
                        do_interrupt(regs);
                else
                        do_trap_unknown(regs);
                break;
        case EXC_INST_ACCESS:
                do_trap_insn_fault(regs);
                break;
        case EXC_ILLEGAL_INST:
                do_trap_insn_illegal(regs);
                break;
        case EXC_BREAKPOINT:
                do_trap_break(regs);
                break;
        case EXC_LOAD_MISALIGNED:
                do_trap_load_misaligned(regs);
                break;
        case EXC_LOAD_ACCESS:
                do_trap_load_fault(regs);
                break;
        case EXC_STORE_MISALIGNED:
                do_trap_store_misaligned(regs);
                break;
        case EXC_STORE_ACCESS:
                do_trap_store_fault(regs);
                break;
        case EXC_ECALL_U:
                do_trap_ecall_u(regs);
                break;
        case EXC_ECALL_S:
                do_trap_ecall_s(regs);
                break;
        case EXC_ECALL_M:
                do_trap_ecall_m(regs);
                break;
        case EXC_INST_PAGE_FAULT:
                do_trap_insn_fault(regs);
                break;
        case EXC_LOAD_PAGE_FAULT:
                do_trap_load_fault(regs);
                break;
        case EXC_STORE_PAGE_FAULT:
                do_trap_store_fault(regs);
                break;
        }
}
