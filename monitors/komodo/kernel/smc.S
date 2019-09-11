#include <io/linkage.h>
#include <uapi/komodo/smcapi.h>

#define __SMCCALL(x, y)         \
        ENTRY(y);               \
                li      a7, x;  \
                ecall;          \
                ret;            \
        ENDPROC(y)

#include <uapi/komodo/smccalls.h>

/*
 * kom_multival_t
 * kom_smc_execute(kom_secure_pageno_t dispatcher,
 *                 uintptr_t arg1, uintptr_t arg2, uintptr_t arg3);
 */
ENTRY(kom_smc_execute)
        /* assume t0 and t1 are preserved by smc calls */
        mv      t0, a0
        li      t1, KOM_ERR_INTERRUPTED
        /* call kom_smc_enter */
        li      a7, KOM_SMC_ENTER
        ecall
loop:
        /* call kom_smc_resume */
        bne     a0, t1, done
        mv      a0, t0
        li      a7, KOM_SMC_RESUME
        ecall
        j       loop
done:
        ret
ENDPROC(kom_smc_execute)
