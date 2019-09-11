#include <io/kbuild.h>
#include <sys/errno.h>
#include <uapi/keystone/syscalls.h>
#include <asm/csr_bits/edeleg.h>
#include <asm/csr_bits/pmpcfg.h>
#include "../enclave.h"

void asm_offsets(void)
{
        DEFINE(EINVAL, EINVAL);

        DEFINE(NR_ENCLAVES, NR_ENCLAVES);
        DEFINE(MAX_PAYLOAD_SIZE, MAX_PAYLOAD_SIZE);

        DEFINE(ENCLAVE_FREE, ENCLAVE_FREE);
        DEFINE(ENCLAVE_FRESH, ENCLAVE_FRESH);
        DEFINE(ENCLAVE_RUNNING, ENCLAVE_RUNNING);
        DEFINE(ENCLAVE_IDLE, ENCLAVE_IDLE);

        DEFINE(CONFIG_BOOT_CPU, CONFIG_BOOT_CPU);

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

        DEFINE(__NR_create_enclave, __NR_create_enclave);
        DEFINE(__NR_destroy_enclave, __NR_destroy_enclave);
        DEFINE(__NR_run_enclave, __NR_run_enclave);
        DEFINE(__NR_exit_enclave, __NR_exit_enclave);
        DEFINE(__NR_resume_enclave, __NR_resume_enclave);
}
