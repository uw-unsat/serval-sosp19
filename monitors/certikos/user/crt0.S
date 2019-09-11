#include <asm/entry.h>
#include <asm/setup.h>

        .section .head.text

/*
 * a0: start of region
 * a1: end of code/data
 * a2: end of region
 * assume sp is set up
 */
ENTRY(_start)
        /* save a0 for relocation */
        mv      s0, a0
        call    lib_setup

        call    relocate
        la      t0, supervisor_trap_vector
        csrw    stvec, t0

        call    main
1:
        call    yield
        j       1b

relocate:
        li      a1, KERNEL_VIRTUAL_START
        sub     a1, a1, s0
        /* relocate return address */
        add     ra, ra, a1
        /* relocate stack pointer */
        add     sp, sp, a1
        ret
END(_start)

ENTRY(supervisor_trap_vector)
        add     sp,  sp, -(PT_SIZE_ON_STACK)
        REG_S   x1,  PT_RA(sp)
        REG_S   x5,  PT_T0(sp)
        REG_S   x6,  PT_T1(sp)
        REG_S   x7,  PT_T2(sp)
        REG_S   x10, PT_A0(sp)
        REG_S   x11, PT_A1(sp)
        REG_S   x12, PT_A2(sp)
        REG_S   x13, PT_A3(sp)
        REG_S   x14, PT_A4(sp)
        REG_S   x15, PT_A5(sp)
        REG_S   x16, PT_A6(sp)
        REG_S   x17, PT_A7(sp)
        REG_S   x28, PT_T3(sp)
        REG_S   x29, PT_T4(sp)
        REG_S   x30, PT_T5(sp)
        REG_S   x31, PT_T6(sp)

        mv      a0, sp
        call    do_supervisor_trap

        REG_L   x1,  PT_RA(sp)
        REG_L   x5,  PT_T0(sp)
        REG_L   x6,  PT_T1(sp)
        REG_L   x7,  PT_T2(sp)
        REG_L   x10, PT_A0(sp)
        REG_L   x11, PT_A1(sp)
        REG_L   x12, PT_A2(sp)
        REG_L   x13, PT_A3(sp)
        REG_L   x14, PT_A4(sp)
        REG_L   x15, PT_A5(sp)
        REG_L   x16, PT_A6(sp)
        REG_L   x17, PT_A7(sp)
        REG_L   x28, PT_T3(sp)
        REG_L   x29, PT_T4(sp)
        REG_L   x30, PT_T5(sp)
        REG_L   x31, PT_T6(sp)

        add     sp, sp, PT_SIZE_ON_STACK
        sret
END(supervisor_trap_vector)
