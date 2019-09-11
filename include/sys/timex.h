/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (C) 2012 Regents of the University of California
 */

#pragma once

#include <asm/csr.h>

typedef unsigned long cycles_t;
typedef unsigned long useconds_t;

static inline cycles_t get_cycles(void)
{
        cycles_t n;

        asm volatile("rdcycle %0" : "=r" (n));
        return n;
}

useconds_t uptime(void);
