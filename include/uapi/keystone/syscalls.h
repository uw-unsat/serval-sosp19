#ifndef __SYSCALL
#define __SYSCALL(x, y)
#endif

/* Start keystone syscalls from 9, reserve 0-8 for SBI */

#define __NR_create_enclave 9
__SYSCALL(__NR_create_enclave, sys_create_enclave)

#define __NR_destroy_enclave 10
__SYSCALL(__NR_destroy_enclave, sys_destroy_enclave)

#define __NR_run_enclave 11
__SYSCALL(__NR_run_enclave, sys_run_enclave)

#define __NR_exit_enclave 12
__SYSCALL(__NR_exit_enclave, sys_exit_enclave)

#define __NR_resume_enclave 13
__SYSCALL(__NR_resume_enclave, sys_resume_enclave)
