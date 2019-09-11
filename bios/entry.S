#include <asm/entry.h>
#include <asm/csr.h>

        .text

ENTRY(machine_trap_vector)
        SAVE_REGS scratch=mscratch

        mv      a0, sp
        csrr    a1, mcause
        call    do_trap

restore_regs:
        RESTORE_REGS
        mret
END(machine_trap_vector)

ENTRY(mret_with_regs)
        /* a0 holds pt_regs */
        mv      sp, a0
        j       restore_regs
END(mret_with_regs)

ENTRY(mret)
        mret
END(mret)
