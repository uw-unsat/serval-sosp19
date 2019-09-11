#pragma once

#include <asm/page.h>
#include <asm/pmp.h>
#include <sys/log2.h>

#define MAX_PAYLOAD_SIZE        SZ_1G

extern char _payload_start[MAX_PAYLOAD_SIZE];

static inline bool is_region_valid(phys_addr_t lower, phys_addr_t upper)
{
        return !(lower % 4) &&
               !(upper % 4) &&
               lower < upper &&
               upper <= MAX_PAYLOAD_SIZE;
}

void *offset_to_virt(uintptr_t offset);

void pmp_debug_print(void);
void free_pmp_region(unsigned long i);
void chmod_pmp_region(unsigned long i, unsigned long perm);
void remap_pmp_region(unsigned long i, uintptr_t lower, uintptr_t upper);
void remap_os_region(void);
void remap_shared_region(uintptr_t lower, uintptr_t upper);
void reset_pmp_state(void);
