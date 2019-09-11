#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <asm/ptrace.h>
#include "pmp.h"
#include "cpu.h"

/*
 * OS takes the last two registers;
 * each enclave takes 2 PMP registers.
 */
#define NR_ENCLAVES ((NR_PMP_ENTRIES - 2) / 2)

enum enclave_status {
        ENCLAVE_FREE = 0,
        ENCLAVE_FRESH,
        ENCLAVE_RUNNING,
        ENCLAVE_IDLE,
};

struct enclave {
        unsigned long status;
        uintptr_t entry;

        uintptr_t secure_lower;
        uintptr_t secure_upper;

        uintptr_t shared_lower;
        uintptr_t shared_upper;

        struct cpu_state encl_state;

        /* padding to 512 bytes */
        char pad0[120];
};

BUILD_BUG_ON(sizeof(struct enclave) != 512);

typedef uint64_t eid_t;

extern void init_enclave(void);
extern long sys_create_enclave(eid_t eid, uintptr_t entry,
                               uintptr_t secure_lower, uintptr_t secure_upper,
                               uintptr_t shared_lower, uintptr_t shared_upper);
extern long sys_destroy_enclave(eid_t eid);
extern long sys_run_enclave(eid_t eid);
extern long sys_exit_enclave(void);
extern long sys_resume_enclave(eid_t eid);
