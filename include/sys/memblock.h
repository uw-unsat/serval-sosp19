/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Logical memory blocks.
 *
 * Copyright (C) 2001 Peter Bergner, IBM Corp.
 */

#pragma once

#include <sys/types.h>

#define INIT_MEMBLOCK_REGIONS   128

struct memblock_region {
        phys_addr_t base;
        phys_addr_t size;
};

struct memblock_type {
        unsigned long cnt;      /* number of regions */
        unsigned long max;      /* size of the allocated array */
        phys_addr_t total_size; /* size of all regions */
        struct memblock_region *regions;
        char *name;
};

struct memblock {
        struct memblock_type memory;
        struct memblock_type reserved;
};

extern struct memblock memblock;

int memblock_add(phys_addr_t base, phys_addr_t size);
int memblock_reserve(phys_addr_t base, phys_addr_t size);
phys_addr_t memblock_alloc(phys_addr_t size, phys_addr_t align);
void memblock_dump_all(void);

void __next_mem_range_rev(uint64_t *idx,
                          struct memblock_type *type_a,
                          struct memblock_type *type_b,
                          phys_addr_t *out_start, phys_addr_t *out_end);

#define for_each_memblock(memblock_type, region)                                        \
        for (region = memblock.memblock_type.regions;                                   \
             region < (memblock.memblock_type.regions + memblock.memblock_type.cnt);    \
             region++)

#define for_each_memblock_type(i, memblock_type, rgn)                   \
        for (i = 0, rgn = &memblock_type->regions[0];                   \
             i < memblock_type->cnt;                                    \
             i++, rgn = &memblock_type->regions[i])

/**
 * for_each_mem_range_rev - reverse iterate through memblock areas from
 * type_a and not included in type_b. Or just type_a if type_b is NULL.
 * @i: u64 used as loop variable
 * @type_a: ptr to memblock_type to iterate
 * @type_b: ptr to memblock_type which excludes from the iteration
 * @p_start: ptr to phys_addr_t for start address of the range, can be %NULL
 * @p_end: ptr to phys_addr_t for end address of the range, can be %NULL
 */
#define for_each_mem_range_rev(i, type_a, type_b, p_start, p_end)       \
        for (i = (uint64_t)ULLONG_MAX,                                  \
                     __next_mem_range_rev(&i, type_a, type_b,           \
                                          p_start, p_end);              \
             i != (uint64_t)ULLONG_MAX;                                 \
             __next_mem_range_rev(&i, type_a, type_b, p_start, p_end))  \

/**
 * for_each_free_mem_range_reverse - rev-iterate through free memblock areas
 * @i: u64 used as loop variable
 * @p_start: ptr to phys_addr_t for start address of the range, can be %NULL
 * @p_end: ptr to phys_addr_t for end address of the range, can be %NULL
 *
 * Walks over free (memory && !reserved) areas of memblock in reverse
 * order.  Available as soon as memblock is initialized.
 */
#define for_each_free_mem_range_reverse(i, p_start, p_end)              \
        for_each_mem_range_rev(i, &memblock.memory, &memblock.reserved, \
                               p_start, p_end)
