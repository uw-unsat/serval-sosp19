#pragma once

#include <sys/types.h>

/* "Kmdo" */
#define KOM_MAGIC               0x4b6d646f

#define KOM_ERR_SUCCESS         0
#define KOM_ERR_INVALID_PAGENO  1
#define KOM_ERR_PAGEINUSE       2
#define KOM_ERR_INVALID_ADDRSPACE 3
#define KOM_ERR_ALREADY_FINAL   4
#define KOM_ERR_NOT_FINAL       5
#define KOM_ERR_INVALID_MAPPING 6
#define KOM_ERR_ADDRINUSE       7
#define KOM_ERR_NOT_STOPPED     8
#define KOM_ERR_INTERRUPTED     9
#define KOM_ERR_FAULT           10
#define KOM_ERR_ALREADY_ENTERED 11
#define KOM_ERR_NOT_ENTERED     12
#define KOM_ERR_INVALID         ((kom_err_t) -1)

#ifndef __ASSEMBLER__

typedef long kom_err_t;
typedef struct {
        kom_err_t err;
        uintptr_t val;
} kom_multival_t;

typedef unsigned long kom_secure_pageno_t;
typedef unsigned long kom_insecure_pageno_t;

/* return KOM_MAGIC */
long kom_smc_query(void);

/* return number of secure pages */
long kom_smc_get_phys_pages(void);

kom_err_t kom_smc_init_addrspace(kom_secure_pageno_t addrspace_page,
                                 kom_secure_pageno_t l1pt_page);

kom_err_t kom_smc_init_dispatcher(kom_secure_pageno_t page,
                                  kom_secure_pageno_t addrspace_page,
                                  uintptr_t entrypoint);

kom_err_t kom_smc_init_l2ptable(kom_secure_pageno_t page,
                                kom_secure_pageno_t l1pt_page,
                                size_t l1_index);

kom_err_t kom_smc_init_l3ptable(kom_secure_pageno_t page,
                                kom_secure_pageno_t l2pt_page,
                                size_t l2_index);

#define KOM_MAPPING_R           (1UL << 1)
#define KOM_MAPPING_W           (1UL << 2)
#define KOM_MAPPING_X           (1UL << 3)
#define KOM_MAPPING_RWX         (KOM_MAPPING_R | KOM_MAPPING_W | KOM_MAPPING_X)

kom_err_t kom_smc_map_secure(kom_secure_pageno_t page,
                             kom_secure_pageno_t l3ptable_page,
                             size_t l3_index,
                             uint64_t mapping,
                             kom_insecure_pageno_t content);

kom_err_t kom_smc_map_insecure(kom_secure_pageno_t l3ptable_page,
                               size_t l3_index,
                               uint64_t mapping,
                               kom_insecure_pageno_t pageno);

kom_err_t kom_smc_remove(kom_secure_pageno_t page);

kom_err_t kom_smc_finalise(kom_secure_pageno_t addrspace);
kom_err_t kom_smc_stop(kom_secure_pageno_t addrspace);

kom_err_t kom_smc_enter(kom_secure_pageno_t disp_page, uintptr_t arg1,
                             uintptr_t arg2, uintptr_t arg3);
kom_err_t kom_smc_resume(kom_secure_pageno_t disp_page);

/* not a real SMC: enter and then resume until !interrupted */
kom_multival_t kom_smc_execute(kom_secure_pageno_t dispatcher, uintptr_t arg1,
                               uintptr_t arg2, uintptr_t arg3);

kom_err_t kom_svc_exit(long exitvalue);

#endif  /* !__ASSEMBLER__ */
