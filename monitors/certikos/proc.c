#include <asm/page.h>
#include <asm/pmp.h>
#include <asm/ptrace.h>
#include <sys/sections.h>
#include <sys/string.h>
#include "proc.h"

struct proc procs[NR_PROCS];
uint8_t pages[NR_PAGES][SZ_4K] __aligned(SZ_4K);

uint64_t current_pid;

void proc_init(void)
{
        size_t i;

        /* mimic a static pid partitoning scheme */
        for (i = 0; i < ARRAY_SIZE(procs); ++i) {
                procs[i].state = PROC_STATE_FREE;
                procs[i].owner = (i >= NR_CHILDREN) ? i / NR_CHILDREN : PID_IDLE;
                procs[i].next = 0;
                procs[i].lower = 0;
                procs[i].upper = 0;

                procs[i].satp = 0;
                procs[i].scause = 0;
                procs[i].scounteren = 0;
                procs[i].sepc = 0;
                procs[i].sscratch = 0;
                procs[i].sstatus = 0;
                procs[i].stvec = 0;
                procs[i].stval = 0;
                procs[i].sip = 0;
                procs[i].sie = 0;
        }

        /* initially run idle */
        current_pid = PID_IDLE;
}

void proc_new(uint64_t pid, uint64_t next, uint64_t fileid, uint64_t lower, uint64_t upper)
{
        struct proc *proc;
        struct pt_regs *cpu;

        BUG_ON(pid >= ARRAY_SIZE(procs));
        proc = &procs[pid];

        BUG_ON(proc->state != PROC_STATE_FREE);
        proc->state = PROC_STATE_RUN;
        proc->next = next;

        proc->lower = lower;
        proc->upper = upper;

        proc->mepc = (uintptr_t) _payload_start;

        cpu = &proc->cpu;
        memset(cpu, 0, sizeof(*cpu));
        cpu->a0 = fileid;
        cpu->a1 = (uintptr_t)pages + lower * SZ_4K;

        /* Initialize memory; otherwise we might leak data from parent to child. */
        memset(&pages[lower], 0, (upper - lower) * SZ_4K);
}

void proc_switch(uint64_t pid)
{
        struct proc *proc;

        BUG_ON(pid >= ARRAY_SIZE(procs));
        proc = &procs[pid];

        /* switch pmp & flush tlb */
        pmpaddr_write(pmpaddr0, (uintptr_t)(&pages[proc->lower]));
        pmpaddr_write(pmpaddr1, (uintptr_t)(&pages[proc->upper]));
        local_flush_tlb_all();

        proc_restore_csrs(proc);
        mret_with_regs(&proc->cpu);
}

struct proc *proc_current(void)
{
        return proc_get(current_pid);
}

struct proc *proc_get(uint64_t pid)
{
        return &procs[pid];
}

bool is_pid_valid(uint64_t pid)
{
        return pid > 0 && pid < NR_PROCS;
}

bool is_proc_free(uint64_t pid)
{
        return procs[pid].state == PROC_STATE_FREE;
}

bool is_pid_owned_by_current(uint64_t pid)
{
        return procs[pid].owner == current_pid;
}

void proc_save_csrs(struct proc *proc)
{
        proc->satp = csr_read(satp);
        proc->scause = csr_read(scause);
        proc->scounteren = csr_read(scounteren);
        proc->sepc = csr_read(sepc);
        proc->sscratch = csr_read(sscratch);
        proc->sstatus = csr_read(sstatus);
        proc->stvec = csr_read(stvec);
        proc->stval = csr_read(stval);
        proc->mepc = csr_read(mepc);
        proc->sie = csr_read(sie);
        proc->sip = csr_read(sip);
}

void proc_restore_csrs(struct proc *proc)
{
        csr_write(satp, proc->satp);
        csr_write(scause, proc->scause);
        csr_write(scounteren, proc->scounteren);
        csr_write(sepc, proc->sepc);
        csr_write(sscratch, proc->sscratch);
        csr_write(sstatus, proc->sstatus);
        csr_write(stvec, proc->stvec);
        csr_write(stval, proc->stval);
        csr_write(mepc, proc->mepc);
        csr_write(sie, proc->sie);
        csr_write(sip, proc->sip);
}
