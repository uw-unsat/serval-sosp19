#pragma once

#include <asm/ptrace.h>
#include <sys/types.h>
#include <uapi/certikos/param.h>

enum {
        PROC_STATE_FREE = 0,
        PROC_STATE_RUN,
};

enum {
        PID_IDLE        = 1,
};

struct proc {
        uint64_t state;
        uint64_t owner;
        uint64_t next;

        uint64_t lower;
        uint64_t upper;

        uint64_t satp;
        uint64_t scause;
        uint64_t scounteren;
        uint64_t sepc;
        uint64_t sscratch;
        uint64_t sstatus;
        uint64_t stvec;
        uint64_t stval;
        uint64_t mepc;
        uint64_t sip;
        uint64_t sie;

        struct pt_regs cpu;

        uint64_t padding[(512 - 376) / 8];
};

BUILD_BUG_ON(sizeof(struct proc) != 512);

extern uint64_t current_quantum;
extern uint64_t current_pid;

extern uint8_t pages[NR_PAGES][SZ_4K];

void proc_init(void);
void proc_new(uint64_t pid, uint64_t next, uint64_t fileid, uint64_t lower, uint64_t upper);

struct proc *proc_current(void);
struct proc *proc_get(uint64_t pid);
bool is_pid_valid(uint64_t pid);
bool is_proc_free(uint64_t pid);
bool is_pid_owned_by_current(uint64_t pid);
bool is_quantum_owned_by_current(uint64_t quantum);
uint64_t quantum_get(uint64_t quantum);
void quantum_sched(uint64_t quantum, uint64_t pid);

noreturn void proc_switch(uint64_t pid);
void proc_save_csrs(struct proc *proc);
void proc_restore_csrs(struct proc *proc);
