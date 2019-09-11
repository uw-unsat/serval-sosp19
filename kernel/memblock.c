// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Procedures for maintaining information about logical memory blocks.
 *
 * Peter Bergner, IBM Corp.     June 2001.
 * Copyright (C) 2001 Peter Bergner.
 */

#include <asm/cache.h>
#include <sys/errno.h>
#include <sys/memblock.h>
#include <sys/string.h>

static struct memblock_region memblock_memory_init_regions[INIT_MEMBLOCK_REGIONS];
static struct memblock_region memblock_reserved_init_regions[INIT_MEMBLOCK_REGIONS];

struct memblock memblock = {
        .memory.regions         = memblock_memory_init_regions,
        .memory.cnt             = 1,    /* empty dummy entry */
        .memory.max             = INIT_MEMBLOCK_REGIONS,
        .memory.name            = "memory",

        .reserved.regions       = memblock_reserved_init_regions,
        .reserved.cnt           = 1,    /* empty dummy entry */
        .reserved.max           = INIT_MEMBLOCK_REGIONS,
        .reserved.name          = "reserved",
};

/* adjust *@size so that (@base + *@size) doesn't overflow, return new size */
static inline phys_addr_t memblock_cap_size(phys_addr_t base, phys_addr_t *size)
{
        return *size = min(*size, PHYS_ADDR_MAX - base);
}

/**
 * memblock_insert_region - insert new memblock region
 * @type:       memblock type to insert into
 * @idx:        index for the insertion point
 * @base:       base address of the new region
 * @size:       size of the new region
 *
 * Insert new memblock region [@base,@base+@size) into @type at @idx.
 * @type must already have extra room to accommodate the new region.
 */
static void memblock_insert_region(struct memblock_type *type, int idx,
                                   phys_addr_t base, phys_addr_t size)
{
        struct memblock_region *rgn = &type->regions[idx];

        BUG_ON(type->cnt >= type->max);
        memmove(rgn + 1, rgn, (type->cnt - idx) * sizeof(*rgn));
        rgn->base = base;
        rgn->size = size;
        type->cnt++;
        type->total_size += size;
}

/**
 * memblock_merge_regions - merge neighboring compatible regions
 * @type: memblock type to scan
 *
 * Scan @type and merge neighboring compatible regions.
 */
static void memblock_merge_regions(struct memblock_type *type)
{
        int i = 0;

        /* cnt never goes below 1 */
        while (i < type->cnt - 1) {
                struct memblock_region *this = &type->regions[i];
                struct memblock_region *next = &type->regions[i + 1];

                if (this->base + this->size != next->base) {
                        BUG_ON(this->base + this->size > next->base);
                        i++;
                        continue;
                }

                this->size += next->size;
                /* move forward from next + 1, index of which is i + 2 */
                memmove(next, next + 1, (type->cnt - (i + 2)) * sizeof(*next));
                type->cnt--;
        }
}

/**
 * memblock_add_range - add new memblock region
 * @type: memblock type to add new region into
 * @base: base address of the new region
 * @size: size of the new region
 *
 * Add new memblock region [@base,@base+@size) into @type.  The new region
 * is allowed to overlap with existing ones - overlaps don't affect already
 * existing regions.  @type is guaranteed to be minimal (all neighbouring
 * compatible regions are merged) after the addition.
 *
 * RETURNS:
 * 0 on success, -errno on failure.
 */
int memblock_add_range(struct memblock_type *type, phys_addr_t base, phys_addr_t size)
{
        bool insert = false;
        phys_addr_t obase = base;
        phys_addr_t end = base + memblock_cap_size(base, &size);
        int idx, nr_new;
        struct memblock_region *rgn;

        if (!size)
                return 0;

        /* special case for empty array */
        if (type->regions[0].size == 0) {
                BUG_ON(type->cnt != 1 || type->total_size);
                type->regions[0].base = base;
                type->regions[0].size = size;
                type->total_size = size;
                return 0;
        }

repeat:
        /*
         * The following is executed twice.  Once with %false @insert and
         * then with %true.  The first counts the number of regions needed
         * to accommodate the new area.  The second actually inserts them.
         */
        base = obase;
        nr_new = 0;

        for_each_memblock_type(idx, type, rgn) {
                phys_addr_t rbase = rgn->base;
                phys_addr_t rend = rbase + rgn->size;

                if (rbase >= end)
                        break;
                if (rend <= base)
                        continue;
                /*
                 * @rgn overlaps.  If it separates the lower part of new
                 * area, insert that portion.
                 */
                if (rbase > base) {
                        nr_new++;
                        if (insert)
                                memblock_insert_region(type, idx++, base, rbase - base);
                }
                /* area below @rend is dealt with, forget about it */
                base = min(rend, end);
        }

        /* insert the remaining portion */
        if (base < end) {
                nr_new++;
                if (insert)
                        memblock_insert_region(type, idx, base, end - base);
        }

        if (!nr_new)
                return 0;

        /*
         * If this was the first round, resize array and repeat for actual
         * insertions; otherwise, merge and return.
         */
        if (!insert) {
                BUG_ON(type->cnt + nr_new > type->max);
                insert = true;
                goto repeat;
        } else {
                memblock_merge_regions(type);
                return 0;
        }
}

int memblock_add(phys_addr_t base, phys_addr_t size)
{
        return memblock_add_range(&memblock.memory, base, size);
}

int memblock_reserve(phys_addr_t base, phys_addr_t size)
{
        return memblock_add_range(&memblock.reserved, base, size);
}

/**
 * memblock_find_in_range_node - find free area in given range and node
 * @size: size of free area to find
 * @align: alignment of free area to find
 *
 * Find @size free area aligned to @align in the specified range and node.
 *
 * RETURNS:
 * Found address on success, 0 on failure.
 */
phys_addr_t memblock_find_in_range_node(phys_addr_t size, phys_addr_t align)
{
        phys_addr_t start = 0, end = PHYS_ADDR_MAX;
        phys_addr_t this_start, this_end, cand;
        uint64_t i;

        for_each_free_mem_range_reverse(i, &this_start, &this_end) {
                this_start = clamp(this_start, start, end);
                this_end = clamp(this_end, start, end);

                if (this_end < size)
                        continue;

                cand = rounddown(this_end - size, align);
                if (cand >= this_start)
                        return cand;
        }

        return 0;
}

phys_addr_t memblock_alloc(phys_addr_t size, phys_addr_t align)
{
        phys_addr_t found;

        if (!align)
                align = SMP_CACHE_BYTES;

        found = memblock_find_in_range_node(size, align);
        if (found && !memblock_reserve(found, size))
                return found;

        panic("failed to allocate %pa bytes\n", &size);
}

/**
 * __next_mem_range_rev - generic next function for for_each_*_range_rev()
 *
 * Finds the next range from type_a which is not marked as unsuitable
 * in type_b.
 *
 * @idx: pointer to u64 loop variable
 * @type_a: pointer to memblock_type from where the range is taken
 * @type_b: pointer to memblock_type which excludes memory from being taken
 * @out_start: ptr to phys_addr_t for start address of the range, can be %NULL
 * @out_end: ptr to phys_addr_t for end address of the range, can be %NULL
 *
 * Reverse of __next_mem_range().
 */
void __next_mem_range_rev(uint64_t *idx,
                          struct memblock_type *type_a,
                          struct memblock_type *type_b,
                          phys_addr_t *out_start, phys_addr_t *out_end)
{
        int idx_a = *idx & 0xffffffff;
        int idx_b = *idx >> 32;

        if (*idx == (uint64_t)ULLONG_MAX) {
                idx_a = type_a->cnt - 1;
                if (type_b != NULL)
                        idx_b = type_b->cnt;
                else
                        idx_b = 0;
        }

        for (; idx_a >= 0; idx_a--) {
                struct memblock_region *m = &type_a->regions[idx_a];
                phys_addr_t m_start = m->base;
                phys_addr_t m_end = m->base + m->size;

                if (!type_b) {
                        if (out_start)
                                *out_start = m_start;
                        if (out_end)
                                *out_end = m_end;
                        idx_a--;
                        *idx = (uint32_t)idx_a | (uint64_t)idx_b << 32;
                        return;
                }

                /* scan areas before each reservation */
                for (; idx_b >= 0; idx_b--) {
                        struct memblock_region *r;
                        phys_addr_t r_start;
                        phys_addr_t r_end;

                        r = &type_b->regions[idx_b];
                        r_start = idx_b ? r[-1].base + r[-1].size : 0;
                        r_end = idx_b < type_b->cnt ?
                                r->base : PHYS_ADDR_MAX;
                        /*
                         * if idx_b advanced past idx_a,
                         * break out to advance idx_a
                         */

                        if (r_end <= m_start)
                                break;
                        /* if the two regions intersect, we're done */
                        if (m_end > r_start) {
                                if (out_start)
                                        *out_start = max(m_start, r_start);
                                if (out_end)
                                        *out_end = min(m_end, r_end);
                                if (m_start >= r_start)
                                        idx_a--;
                                else
                                        idx_b--;
                                *idx = (uint32_t)idx_a | (uint64_t)idx_b << 32;
                                return;
                        }
                }
        }
        /* signal end of iteration */
        *idx = ULLONG_MAX;
}

static void memblock_dump(struct memblock_type *type)
{
        phys_addr_t base, end, size;
        int idx;
        struct memblock_region *rgn;

        pr_info(" %s.cnt  = 0x%lx\n", type->name, type->cnt);

        for_each_memblock_type(idx, type, rgn) {
                base = rgn->base;
                size = rgn->size;
                end = base + size - 1;
                pr_info(" %s[%#x]\t[%pa-%pa], %pa bytes\n",
                        type->name, idx, &base, &end, &size);
        }
}

void memblock_dump_all(void)
{
        pr_info("MEMBLOCK configuration:\n");
        pr_info(" memory size = %pa reserved size = %pa\n",
                &memblock.memory.total_size,
                &memblock.reserved.total_size);

        memblock_dump(&memblock.memory);
        memblock_dump(&memblock.reserved);
}
