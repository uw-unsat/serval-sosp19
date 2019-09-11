/* SPDX-License-Identifier: GPL-2.0 */
/*
 * ioport.h     Definitions of routines for detecting, reserving and
 *              allocating system resources.
 *
 * Authors:     Linus Torvalds
 */

#pragma once

#include <sys/types.h>

struct resource {
        resource_size_t start;
        resource_size_t end;
        unsigned long flags;
};

#define IORESOURCE_TYPE_BITS    0x00001f00      /* Resource type */
#define IORESOURCE_IO           0x00000100      /* PCI/ISA I/O ports */
#define IORESOURCE_MEM          0x00000200
#define IORESOURCE_IRQ          0x00000400
#define IORESOURCE_DMA          0x00000800
#define IORESOURCE_BUS          0x00001000

#define IORESOURCE_PREFETCH     0x00002000      /* No side effects */

#define IORESOURCE_SIZEALIGN    0x00040000      /* size indicates alignment */

#define IORESOURCE_MEM_64       0x00100000
#define IORESOURCE_WINDOW       0x00200000      /* forwarded by bridge */

#define IORESOURCE_DISABLED     0x10000000
#define IORESOURCE_UNSET        0x20000000      /* No address assigned yet */

static inline resource_size_t resource_size(const struct resource *res)
{
        return res->end - res->start + 1;
}

static inline unsigned long resource_type(const struct resource *res)
{
        return res->flags & IORESOURCE_TYPE_BITS;
}
