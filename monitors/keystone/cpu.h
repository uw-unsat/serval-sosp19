#pragma once

#include <asm/csr.h>
#include <asm/ptrace.h>

struct cpu_state {
#define __CSR(n) uint64_t n;
#include "csrs.h"
#undef __CSR
        struct pt_regs regs;
};

static inline void restore_cpu_state(struct pt_regs *regs, struct cpu_state *state)
{
#define __CSR(n) csr_write(n, state->n);
#include "csrs.h"
#undef __CSR

        copy_pt_regs(regs, &state->regs);
}

static inline void save_cpu_state(struct pt_regs *regs, struct cpu_state *state)
{
#define __CSR(n) state->n = csr_read(n);
#include "csrs.h"
#undef __CSR

        copy_pt_regs(&state->regs, regs);
}
