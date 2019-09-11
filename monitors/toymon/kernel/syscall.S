#include <io/linkage.h>

#define __SYSCALL(x, y)         \
        ENTRY(y);               \
                li      a7, x;  \
                ecall;          \
                ret;            \
        ENDPROC(y)

#include <uapi/toymon/syscalls.h>