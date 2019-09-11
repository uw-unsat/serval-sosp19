#include <asm/csr.h>
#include <asm/ptrace.h>
#include <sys/types.h>

__weak struct pt_regs *current_pt_regs(void)
{
        return (void *)(uintptr_t)csr_read(sscratch);
}

void copy_pt_regs(struct pt_regs *dst, struct pt_regs *src)
{
        dst->ra = src->ra;
        dst->sp = src->sp;
        dst->gp = src->gp;
        dst->tp = src->tp;
        dst->t0 = src->t0;
        dst->t1 = src->t1;
        dst->t2 = src->t2;
        dst->s0 = src->s0;
        dst->s1 = src->s1;
        dst->a0 = src->a0;
        dst->a1 = src->a1;
        dst->a2 = src->a2;
        dst->a3 = src->a3;
        dst->a4 = src->a4;
        dst->a5 = src->a5;
        dst->a6 = src->a6;
        dst->a7 = src->a7;
        dst->s2 = src->s2;
        dst->s3 = src->s3;
        dst->s4 = src->s4;
        dst->s5 = src->s5;
        dst->s6 = src->s6;
        dst->s7 = src->s7;
        dst->s8 = src->s8;
        dst->s9 = src->s9;
        dst->s10 = src->s10;
        dst->s11 = src->s11;
        dst->t3 = src->t3;
        dst->t4 = src->t4;
        dst->t5 = src->t5;
        dst->t6 = src->t6;
}
