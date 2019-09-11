/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Definitions for talking to the Open Firmware PROM on
 * Power Macintosh and other computers.
 *
 * Copyright (C) 1996-2005 Paul Mackerras.
 *
 * Updates for PPC64 by Peter Bergner & David Engebretsen, IBM Corp.
 * Updates for SPARC64 by David S. Miller
 * Derived from PowerPC and Sparc prom.h files by Stephen Rothwell, IBM Corp.
 */

#pragma once

#include <sys/byteorder.h>
#include <sys/types.h>

struct device_node;

#define for_each_of_allnodes_from(from, dn) \
        for (dn = __of_find_all_nodes(from); dn; dn = __of_find_all_nodes(dn))
#define for_each_of_allnodes(dn) for_each_of_allnodes_from(NULL, dn)

struct device_node *__of_find_all_nodes(struct device_node *prev);

struct device_node *of_find_node_by_path(const char *path);
struct device_node *of_find_compatible_node(struct device_node *from, const char *type, const char *compat);

const void *of_get_property(const struct device_node *node, const char *name, int *lenp);
int of_property_read_u32(const struct device_node *np, const char *propname, uint32_t *out_value);

int of_device_is_compatible(const struct device_node *device, const char *compat);

/* Helper to read a big number; size is in cells (not bytes) */
static inline uint64_t of_read_number(const be32_t *cell, int size)
{
        uint64_t r = 0;

        while (size--)
                r = (r << 32) | be32_to_cpu(*(cell++));
        return r;
}

int of_n_addr_cells(struct device_node *np);
int of_n_size_cells(struct device_node *np);

bool early_init_dt_verify(void *params);
void early_init_dt_scan_nodes(void);
bool early_init_dt_scan(void *params);
void early_init_fdt_reserve_self(void);
extern int of_get_flat_dt_size(void);

void of_dt_move(void *buf, size_t size);
