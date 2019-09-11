#ifndef __SYSCALL
#define __SYSCALL(x, y)
#endif

/* start syscalls from 10; reserve lower ones for SBI */

#define __NR_get_shadow_size 10
__SYSCALL(__NR_get_shadow_size, sys_get_shadow_size)

#define __NR_get_region_size 11
__SYSCALL(__NR_get_region_size, sys_get_region_size)

#define __NR_approve 12
__SYSCALL(__NR_approve, sys_approve)

#define __NR_revoke 13
__SYSCALL(__NR_revoke, sys_revoke)

#define __NR_load_pgd 15
__SYSCALL(__NR_load_pgd, sys_load_pgd)

#define __NR_reset_tlb 16
__SYSCALL(__NR_reset_tlb, sys_reset_tlb)

#define __NR_set_pgd_next 20
__SYSCALL(__NR_set_pgd_next, sys_set_pgd_next)

#define __NR_set_pmd_next 21
__SYSCALL(__NR_set_pmd_next, sys_set_pmd_next)

#define __NR_set_pte_leaf 22
__SYSCALL(__NR_set_pte_leaf, sys_set_pte_leaf)

#define __NR_clear_pgd_next 30
__SYSCALL(__NR_clear_pgd_next, sys_clear_pgd_next)

#define __NR_clear_pmd_next 31
__SYSCALL(__NR_clear_pmd_next, sys_clear_pmd_next)

#define __NR_clear_pte_leaf 32
__SYSCALL(__NR_clear_pte_leaf, sys_clear_pte_leaf)
