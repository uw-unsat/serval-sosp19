#include "pmp.h"


void *offset_to_virt(uintptr_t offset)
{
        return &_payload_start[offset];
}

static phys_addr_t offset_to_phys(uintptr_t offset)
{
        return (uintptr_t)offset_to_virt(offset);
}


static void __pmpaddr_write(unsigned long nr, unsigned long addr)
{
        #define PMP_CASE(n) case n: pmpaddr_write(pmpaddr##n, addr); break;
        switch (nr) {
        PMP_CASE(0) PMP_CASE(1) PMP_CASE(2) PMP_CASE(3)
        PMP_CASE(4) PMP_CASE(5) PMP_CASE(6) PMP_CASE(7)
        default: BUG();
        }
        #undef PMP_CASE
}


static unsigned long __pmpaddr_read(unsigned long nr)
{
        #define PMP_CASE(n) case n: return pmpaddr_read(pmpaddr##n);
        switch (nr) {
        PMP_CASE(0) PMP_CASE(1) PMP_CASE(2) PMP_CASE(3)
        PMP_CASE(4) PMP_CASE(5) PMP_CASE(6) PMP_CASE(7)
        default: BUG();
        }
        #undef PMP_CASE
}


void pmp_debug_print(void)
{
        unsigned long cfg, addr;
        int i;

        for (i = 0; i < NR_PMP_ENTRIES; ++i) {
                cfg = pmpcfg_read(i);
                pr_info("pmp%dcfg : ", i);
                if (cfg & PMPCFG_R) pr_info("R"); else pr_info("-");
                if (cfg & PMPCFG_W) pr_info("W"); else pr_info("-");
                if (cfg & PMPCFG_X) pr_info("X"); else pr_info("-");
                if (cfg & PMPCFG_L) pr_info("L"); else pr_info("-");
                switch (cfg & (0x3 << PMPCFG_A_SHIFT)) {
                case PMPCFG_A_NAPOT:
                        pr_info(" NAPOT");
                        break;
                case PMPCFG_A_OFF:
                        pr_info(" OFF");
                        break;
                case PMPCFG_A_TOR:
                        pr_info(" TOR");
                        break;
                case PMPCFG_A_NA4:
                        pr_info(" NA4");
                        break;
                default:
                        BUG();
                }

                pr_info("\n");

                addr = __pmpaddr_read(i);
                pr_info("pmpaddr%d : 0x%016lx\n", i, addr);

        }
}

static unsigned long eid_to_pmp_lower(unsigned long eid)
{
        switch (eid) {
        case 0:
                return 0;
        case 1:
                return 2;
        case 2:
                return 4;
        default:
                BUG();
        }
}

static unsigned long eid_to_pmp_upper(unsigned long eid)
{
        return eid_to_pmp_lower(eid) + 1;
}

void free_pmp_region(unsigned long i)
{
        __pmpaddr_write(eid_to_pmp_lower(i), 0);
        __pmpaddr_write(eid_to_pmp_upper(i), 0);
}

void chmod_pmp_region(unsigned long i, unsigned long perm)
{
        pmpcfg_write(eid_to_pmp_upper(i), PMPCFG_A_TOR | perm);
}

void remap_pmp_region(unsigned long i, uintptr_t lower, uintptr_t upper)
{
        __pmpaddr_write(eid_to_pmp_lower(i), offset_to_phys(lower));
        __pmpaddr_write(eid_to_pmp_upper(i), offset_to_phys(upper));
}

void remap_os_region(void)
{
        __pmpaddr_write(NR_PMP_ENTRIES - 2, offset_to_phys(0));
        __pmpaddr_write(NR_PMP_ENTRIES - 1, offset_to_phys(MAX_PAYLOAD_SIZE));
        pmpcfg_write(NR_PMP_ENTRIES - 1, PMPCFG_A_TOR | PMPCFG_R | PMPCFG_W | PMPCFG_X);
}

void remap_shared_region(uintptr_t lower, uintptr_t upper)
{
        __pmpaddr_write(NR_PMP_ENTRIES - 2, offset_to_phys(lower));
        __pmpaddr_write(NR_PMP_ENTRIES - 1, offset_to_phys(upper));
        pmpcfg_write(NR_PMP_ENTRIES - 1, PMPCFG_A_TOR | PMPCFG_R | PMPCFG_W);
}

void reset_pmp_state(void)
{
        size_t i;

        for (i = 0; i < NR_PMP_ENTRIES; ++i) {
                pmpcfg_write(i, (i % 2) ? PMPCFG_A_TOR : PMPCFG_A_OFF);
                __pmpaddr_write(i, 0);
        }
}
