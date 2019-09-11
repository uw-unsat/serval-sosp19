#ifndef __SYSCALL
#define __SYSCALL(x, y)
#endif

/* start syscalls from 10; reserve lower ones for SBI */

#define __NR_get_quota 10
__SYSCALL(__NR_get_quota, sys_get_quota)

#define __NR_spawn 11
__SYSCALL(__NR_spawn, sys_spawn)

#define __NR_yield 12
__SYSCALL(__NR_yield, sys_yield)

#define __NR_getpid 13
__SYSCALL(__NR_getpid, sys_getpid)

/* alias: sbi_console_putchar */
#define __NR_print 1
__SYSCALL(__NR_print, sys_print)
