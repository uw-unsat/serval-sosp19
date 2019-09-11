#include <asm/entry.h>

        .text

ENTRY(supervisor_trap_vector)
        SAVE_REGS scratch=sscratch

        mv      a0, sp
        csrr    a1, scause
        call    do_trap

restore_regs:
        RESTORE_REGS
        sret
END(supervisor_trap_vector)

ENTRY(restore_regs_and_return_to_user)
        csrr    sp, sscratch
        j       restore_regs
END(restore_regs_and_return_to_user)

#if 0
/*
 * a0 - cause
 * sp - pt_regs
 */
ENTRY(do_trap)
        /* each entry (j offset) has 4 bytes */
        slli    t0, a0, 2
        la      t1, excp_vect_table
        la      t2, excp_vect_table_end
        /* pt_regs */
        move    a0, sp
        add     t0, t1, t0
        /* check if exception code lies within bounds */
        bgeu    t0, t2, 1f
        jr      t0
1:
        j       do_trap_unknown
END(do_trap)

ENTRY(excp_vect_table)
        j       do_trap_insn_misaligned
        j       do_trap_insn_fault
        j       do_trap_insn_illegal
        j       do_trap_break
        j       do_trap_load_misaligned
        j       do_trap_load_fault
        j       do_trap_store_misaligned
        j       do_trap_store_fault
        j       do_trap_ecall_u
        j       do_trap_ecall_s
        j       do_trap_unknown
        j       do_trap_ecall_m
        j       do_trap_insn_fault
        j       do_trap_load_fault
        j       do_trap_unknown
        j       do_trap_store_fault
excp_vect_table_end:
END(excp_vect_table)

#endif
