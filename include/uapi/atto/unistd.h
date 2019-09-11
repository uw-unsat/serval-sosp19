#ifndef __SYSCALL
#define __SYSCALL(x, y)
#endif

/*
 * This file contains the system call numbers.  They are consistent
 * with the Linux system call numbers to make it easier to debug
 * and run user-space programs.
 */

#define __NR_openat 56
__SYSCALL(__NR_openat, sys_openat)

#define __NR_close 57
__SYSCALL(__NR_close, sys_close)

#define __NR_getdents 61
__SYSCALL(__NR_getdents, sys_getdents)

#define __NR_read 63
__SYSCALL(__NR_read, sys_read)

#define __NR_write 64
__SYSCALL(__NR_write, sys_write)

#define __NR_fstat 80
__SYSCALL(__NR_fstat, sys_fstat)

#define __NR_exit 93
__SYSCALL(__NR_exit, sys_exit)

#define __NR_waitid 95
__SYSCALL(__NR_waitid, sys_waitid)

#define __NR_sched_yield 124
__SYSCALL(__NR_sched_yield, sys_sched_yield)

#define __NR_brk 214
__SYSCALL(__NR_brk, sys_brk)

#define __NR_clone 220
__SYSCALL(__NR_clone, sys_clone)

#define __NR_execveat 281
__SYSCALL(__NR_execveat, sys_execveat)
