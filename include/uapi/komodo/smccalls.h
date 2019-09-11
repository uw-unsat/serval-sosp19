#ifndef __SMCCALL
#define __SMCCALL(x, y)
#endif

/* start syscalls from 10; reserve lower ones for SBI */

#define KOM_SMC_QUERY           10
__SMCCALL(KOM_SMC_QUERY, kom_smc_query)

#define KOM_SMC_GETPHYSPAGES    11
__SMCCALL(KOM_SMC_GETPHYSPAGES, kom_smc_get_phys_pages)

#define KOM_SMC_INIT_ADDRSPACE  12
__SMCCALL(KOM_SMC_INIT_ADDRSPACE, kom_smc_init_addrspace)

#define KOM_SMC_INIT_DISPATCHER 13
__SMCCALL(KOM_SMC_INIT_DISPATCHER, kom_smc_init_dispatcher)

#define KOM_SMC_INIT_L2PTABLE   14
__SMCCALL(KOM_SMC_INIT_L2PTABLE, kom_smc_init_l2ptable)

#define KOM_SMC_INIT_L3PTABLE   15
__SMCCALL(KOM_SMC_INIT_L3PTABLE, kom_smc_init_l3ptable)

#define KOM_SMC_MAP_SECURE      16
__SMCCALL(KOM_SMC_MAP_SECURE, kom_smc_map_secure)

#define KOM_SMC_MAP_INSECURE    17
__SMCCALL(KOM_SMC_MAP_INSECURE, kom_smc_map_insecure)

#define KOM_SMC_COPY_DATA       18
__SMCCALL(KOM_SMC_COPY_DATA, kom_smc_copy_data)

#define KOM_SMC_REMOVE          20
__SMCCALL(KOM_SMC_REMOVE, kom_smc_remove)

#define KOM_SMC_FINALISE        21
__SMCCALL(KOM_SMC_FINALISE, kom_smc_finalise)

#define KOM_SMC_ENTER           22
__SMCCALL(KOM_SMC_ENTER, kom_smc_enter)

#define KOM_SMC_RESUME          23
__SMCCALL(KOM_SMC_RESUME, kom_smc_resume)

#define KOM_SMC_STOP            29
__SMCCALL(KOM_SMC_STOP, kom_smc_stop)
