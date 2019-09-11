#include <io/kbuild.h>
#include <sys/errno.h>
#include <uapi/certikos/param.h>
#include <uapi/certikos/syscalls.h>
#include <asm/csr_bits/edeleg.h>
#include <asm/csr_bits/pmpcfg.h>
#include "../proc.h"

void asm_offsets(void)
{
        DEFINE(EINVAL, EINVAL);
        DEFINE(ENOSYS, ENOSYS);

        DEFINE(NR_PROCS, NR_PROCS);
        DEFINE(NR_CHILDREN, NR_CHILDREN);
        DEFINE(NR_PAGES, NR_PAGES);
        DEFINE(NR_QUANTA, NR_QUANTA);

        DEFINE(PROC_STATE_FREE, PROC_STATE_FREE);
        DEFINE(PROC_STATE_RUN, PROC_STATE_RUN);

        DEFINE(CONFIG_BOOT_CPU, CONFIG_BOOT_CPU);

        DEFINE(__NR_get_quota, __NR_get_quota);
        DEFINE(__NR_spawn, __NR_spawn);
        DEFINE(__NR_yield, __NR_yield);
        DEFINE(__NR_getpid, __NR_getpid);
        DEFINE(__NR_print, __NR_print);

        DEFINE(EXC_ECALL_S, EXC_ECALL_S);

        DEFINE(PMPCFG_A_OFF, PMPCFG_A_OFF);
        DEFINE(PMPCFG_A_NAPOT, PMPCFG_A_NAPOT);
        DEFINE(PMPCFG_A_TOR, PMPCFG_A_TOR);
        DEFINE(PMPCFG_R, PMPCFG_R);
        DEFINE(PMPCFG_W, PMPCFG_W);
        DEFINE(PMPCFG_X, PMPCFG_X);
        DEFINE(PMPCFG_RWX, PMPCFG_RWX);

        DEFINE(EDEL_BREAKPOINT, EDEL_BREAKPOINT);
        DEFINE(EDEL_ECALL_U, EDEL_ECALL_U);
        DEFINE(EDEL_INST_MISALIGNED, EDEL_INST_MISALIGNED);
        DEFINE(EDEL_INST_PAGE_FAULT, EDEL_INST_PAGE_FAULT);
        DEFINE(EDEL_LOAD_MISALIGNED, EDEL_LOAD_MISALIGNED);
        DEFINE(EDEL_LOAD_PAGE_FAULT, EDEL_LOAD_PAGE_FAULT);
        DEFINE(EDEL_STORE_MISALIGNED, EDEL_STORE_MISALIGNED);
        DEFINE(EDEL_STORE_PAGE_FAULT, EDEL_STORE_PAGE_FAULT);
}
