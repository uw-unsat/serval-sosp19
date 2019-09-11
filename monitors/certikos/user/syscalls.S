#include <io/linkage.h>

#define __SYSCALL(x, y)         \
        ENTRY(y);               \
                li      a7, x;  \
                ecall;          \
                ret;            \
        ENDPROC(y)

#include <uapi/certikos/syscalls.h>

/* SYSCALL_ALIAS(get_quota, sys_get_quota) */
/* SYSCALL_ALIAS(spawn, sys_spawn) */
SYSCALL_ALIAS(yield, sys_yield)
SYSCALL_ALIAS(print, sys_print)
