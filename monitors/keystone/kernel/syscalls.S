#include <io/linkage.h>

#define __SYSCALL(x, y)         \
        ENTRY(y);               \
                li      a7, x;  \
                ecall;          \
                ret;            \
        ENDPROC(y)

#include <uapi/keystone/syscalls.h>

SYSCALL_ALIAS(destroy_enclave, sys_destroy_enclave)
SYSCALL_ALIAS(run_enclave, sys_run_enclave)
SYSCALL_ALIAS(exit_enclave, sys_exit_enclave)
SYSCALL_ALIAS(resume_enclave, sys_resume_enclave)
