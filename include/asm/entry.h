#pragma once

#include <asm/asm-offsets.h>
#include <asm/setup.h>
#include <io/asm.h>
#include <io/linkage.h>

        .macro SAVE_REGS scratch:req
        /*
         * Load kernel sp and save user sp temporarily in scratch first.
         * Note that if the trap comes from kernel (which shouldn't happen
         * as we assume no recursive traps), sp will be reset to scratch.
         */
        csrrw   sp, \scratch, sp

        REG_S   x1,  PT_RA(sp)
        /* save x2/sp in the end */
        REG_S   x3,  PT_GP(sp)
        REG_S   x4,  PT_TP(sp)
        REG_S   x5,  PT_T0(sp)
        REG_S   x6,  PT_T1(sp)
        REG_S   x7,  PT_T2(sp)
        REG_S   x8,  PT_S0(sp)
        REG_S   x9,  PT_S1(sp)
        REG_S   x10, PT_A0(sp)
        REG_S   x11, PT_A1(sp)
        REG_S   x12, PT_A2(sp)
        REG_S   x13, PT_A3(sp)
        REG_S   x14, PT_A4(sp)
        REG_S   x15, PT_A5(sp)
        REG_S   x16, PT_A6(sp)
        REG_S   x17, PT_A7(sp)
        REG_S   x18, PT_S2(sp)
        REG_S   x19, PT_S3(sp)
        REG_S   x20, PT_S4(sp)
        REG_S   x21, PT_S5(sp)
        REG_S   x22, PT_S6(sp)
        REG_S   x23, PT_S7(sp)
        REG_S   x24, PT_S8(sp)
        REG_S   x25, PT_S9(sp)
        REG_S   x26, PT_S10(sp)
        REG_S   x27, PT_S11(sp)
        REG_S   x28, PT_T3(sp)
        REG_S   x29, PT_T4(sp)
        REG_S   x30, PT_T5(sp)
        REG_S   x31, PT_T6(sp)

        /* restore scratch & save user sp */
        csrrw   tp, \scratch, sp
        REG_S   tp,  PT_SP(sp)
        .endm

        .macro RESTORE_REGS
        REG_L   x1,  PT_RA(sp)
        /* restore x2/sp in the end */
        REG_L   x3,  PT_GP(sp)
        REG_L   x4,  PT_TP(sp)
        REG_L   x5,  PT_T0(sp)
        REG_L   x6,  PT_T1(sp)
        REG_L   x7,  PT_T2(sp)
        REG_L   x8,  PT_S0(sp)
        REG_L   x9,  PT_S1(sp)
        REG_L   x10, PT_A0(sp)
        REG_L   x11, PT_A1(sp)
        REG_L   x12, PT_A2(sp)
        REG_L   x13, PT_A3(sp)
        REG_L   x14, PT_A4(sp)
        REG_L   x15, PT_A5(sp)
        REG_L   x16, PT_A6(sp)
        REG_L   x17, PT_A7(sp)
        REG_L   x18, PT_S2(sp)
        REG_L   x19, PT_S3(sp)
        REG_L   x20, PT_S4(sp)
        REG_L   x21, PT_S5(sp)
        REG_L   x22, PT_S6(sp)
        REG_L   x23, PT_S7(sp)
        REG_L   x24, PT_S8(sp)
        REG_L   x25, PT_S9(sp)
        REG_L   x26, PT_S10(sp)
        REG_L   x27, PT_S11(sp)
        REG_L   x28, PT_T3(sp)
        REG_L   x29, PT_T4(sp)
        REG_L   x30, PT_T5(sp)
        REG_L   x31, PT_T6(sp)

        /* restore sp */
        REG_L   x2,  PT_SP(sp)
        .endm
