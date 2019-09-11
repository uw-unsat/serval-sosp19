#include <asm/entry.h>

        .section .text

/*
 * a0: guest pt_regs
 */
ENTRY(test_enter)
        /* save M-mode registers */
        add     sp, sp, -(PT_SIZE_ON_STACK)
        csrw    mscratch, sp
        /* load guest registers */
        SAVE_REGS scratch=mscratch
        csrw    mscratch, a0
        RESTORE_REGS
        mret
END(test_enter)

ENTRY(test_exit)
        /* mscratch points to pt_regs */
        SAVE_REGS scratch=mscratch
        /* restore M-mode registers */
        csrw    mscratch, sp
        RESTORE_REGS
        add     sp, sp, PT_SIZE_ON_STACK
        ret
END(test_exit)

ENTRY(noop_test)
        nop
        ret
END(noop_test)


        .section .rodata
        .balign RISCV_SZPTR
GLOBAL(suites_start)
     /* RISCV_PTR arith_test
        RISCV_PTR counteren_test
        RISCV_PTR pmp_test */
        RISCV_PTR ebpf_test
GLOBAL(suites_end)

GLOBAL(_payload_start)
GLOBAL(_payload_end)
