#include <asm/csr.h>
#include <asm/tlbflush.h>
#include <sys/errno.h>
#include <sys/console.h>
#include <sys/string.h>
#include "enclave.h"

/* eid in [1 .. NR_PMP_ENTRIES - 1] */
struct enclave enclaves[NR_ENCLAVES];
bool enclave_mode;
eid_t current_enclave;
struct cpu_state host_state;

static inline bool eid_is_valid(eid_t eid)
{
        return eid < NR_ENCLAVES;
}

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM)
static void inline save_host_state(struct pt_regs *regs)
{
        save_cpu_state(regs, &host_state);
}

static void inline restore_host_state(struct pt_regs *regs)
{
        restore_cpu_state(regs, &host_state);
}

static void inline save_encl_state(struct pt_regs *regs, eid_t eid)
{
        save_cpu_state(regs, &enclaves[eid].encl_state);
}

static void inline restore_encl_state(struct pt_regs *regs, eid_t eid)
{
        restore_cpu_state(regs, &enclaves[eid].encl_state);
}
#endif

static bool is_region_overlap(uintptr_t lower, size_t upper)
{
        size_t i;

        for (i = 0; i < NR_ENCLAVES; ++i) {
                if (enclaves[i].secure_upper > lower &&
                    upper > enclaves[i].secure_lower)
                        return true;
        }

        return false;
}

/*
 * Initial setup
 */
void init_enclave(void)
{
        enclave_mode = false;
        memset(enclaves, 0, sizeof(enclaves));
}

long sys_create_enclave(eid_t eid, uintptr_t entry,
                        uintptr_t secure_lower, size_t secure_upper,
                        uintptr_t shared_lower, size_t shared_upper)
{
        if (enclave_mode)
                return -EINVAL;
        if (!eid_is_valid(eid))
                return -EINVAL;
        if (enclaves[eid].status != ENCLAVE_FREE)
                return -EINVAL;

        if (!is_region_valid(secure_lower, secure_upper))
                return -EINVAL;

        if (!is_region_valid(shared_lower, shared_upper))
                return -EINVAL;

        /*
         * A secure region cannot overlap with any other secure region.
         *
         * It's okay for a secure region to overlap with another enclave's
         * shared region; this will block accesses to that shared region.
         */
        if (is_region_overlap(secure_lower, secure_upper))
                return -EINVAL;

        enclaves[eid].secure_lower = secure_lower;
        enclaves[eid].secure_upper = secure_upper;
        enclaves[eid].shared_lower = shared_lower;
        enclaves[eid].shared_upper = shared_upper;

        enclaves[eid].entry = entry;
        enclaves[eid].status = ENCLAVE_FRESH;

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM) && !IS_ENABLED(CONFIG_VERIFICATION)
        /* block accesses to the newly created enclave */
        chmod_pmp_region(eid, 0);
        remap_pmp_region(eid, secure_lower, secure_upper);

        local_flush_tlb_all();
#endif

        return 0;
}


long sys_destroy_enclave(eid_t eid)
{
        size_t size;

        if (enclave_mode)
                return -EINVAL;
        if (!eid_is_valid(eid))
                return -EINVAL;
        if (enclaves[eid].status != ENCLAVE_IDLE &&
            enclaves[eid].status != ENCLAVE_FRESH)
                return -EINVAL;

        size = enclaves[eid].secure_upper - enclaves[eid].secure_lower;
        memset(offset_to_virt(enclaves[eid].secure_lower), 0, size);

        enclaves[eid].status = ENCLAVE_FREE;
        enclaves[eid].secure_lower = 0;
        enclaves[eid].secure_upper = 0;

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM) && !IS_ENABLED(CONFIG_VERIFICATION)
        free_pmp_region(eid);

        local_flush_tlb_all();
#endif

        return 0;
}


long sys_run_enclave(eid_t eid)
{
        if (enclave_mode)
                return -EINVAL;
        if (!eid_is_valid(eid))
                return -EINVAL;
        if (enclaves[eid].status != ENCLAVE_IDLE &&
            enclaves[eid].status != ENCLAVE_FRESH)
                return -EINVAL;

        enclaves[eid].encl_state.mepc = enclaves[eid].entry;
        memset(&enclaves[eid].encl_state.regs, 0, sizeof(struct pt_regs));
        enclaves[eid].status = ENCLAVE_IDLE;

        return sys_resume_enclave(eid);
}


long sys_exit_enclave(void)
{
        eid_t eid = current_enclave;

        if (!enclave_mode)
                return -EINVAL;

        enclave_mode = false;
        current_enclave = -1;
        enclaves[eid].status = ENCLAVE_IDLE;

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM) && !IS_ENABLED(CONFIG_VERIFICATION)
        save_encl_state(current_pt_regs(), eid);
        restore_host_state(current_pt_regs());

        /* block this secure region */
        chmod_pmp_region(eid, 0);

        /* enable everything else for OS */
        remap_os_region();

        local_flush_tlb_all();
#endif

        return 0;
}


long sys_resume_enclave(eid_t eid)
{
        if (enclave_mode)
                return -EINVAL;
        if (!eid_is_valid(eid))
                return -EINVAL;
        if (enclaves[eid].status != ENCLAVE_IDLE)
                return -EINVAL;

        enclave_mode = true;
        current_enclave = eid;
        enclaves[eid].status = ENCLAVE_RUNNING;

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM) && !IS_ENABLED(CONFIG_VERIFICATION)
        save_host_state(current_pt_regs());
        restore_encl_state(current_pt_regs(), eid);

        /* enable RWX accesses to the secure region */
        chmod_pmp_region(eid, PMPCFG_R | PMPCFG_W | PMPCFG_X);

        /* enable RW accesses to the shared region */
        remap_shared_region(enclaves[eid].shared_lower, enclaves[eid].shared_upper);

        local_flush_tlb_all();
#endif

        return 0;
}
