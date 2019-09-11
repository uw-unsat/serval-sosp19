#pragma once

#include <asm/pgtable.h>
#include <asm/ptrace.h>
#include <uapi/komodo/memregions.h>
#include <uapi/komodo/smcapi.h>
#include <uapi/komodo/smccalls.h>
#include <uapi/komodo/svccalls.h>

extern kom_err_t kom_handle_trap(long cause);

#define _PAGE_ENCLAVE   (_PAGE_PRESENT | _PAGE_ACCESSED | _PAGE_DIRTY)

typedef enum {
        KOM_PAGE_FREE = 0,
        KOM_PAGE_ADDRSPACE,
        KOM_PAGE_DISPATCHER,
        KOM_PAGE_L1PTABLE,
        KOM_PAGE_L2PTABLE,
        KOM_PAGE_L3PTABLE,
        KOM_PAGE_DATA,
        KOM_PAGE_INVALID = -1
} kom_pagetype_t;

struct kom_pagedb_entry {
        uint64_t type;
        /*
         * Komodo records a pointer to struct kom_addrspace.
         * We use a page index instead.
         */
        uint64_t addrspace_page;
};

typedef enum {
        KOM_ADDRSPACE_INIT = 0,
        KOM_ADDRSPACE_FINAL = 1,
        KOM_ADDRSPACE_STOPPED = 2,
} kom_addrspace_state_t;

struct kom_addrspace {
        /*
         * Komodo records both virtual and physical addresses of l1pt.
         * We store just the l1pt index.
         */
        uint64_t l1pt_page;
        uint64_t refcount;
        uint64_t state;
};

struct kom_dispatcher {
        uint64_t entered; // bool
        struct pt_regs regs;
#define __CSR(n) unsigned long n;
#       include "csrs.h"
#undef __CSR
};

struct host_state {
        struct pt_regs regs;
#define __CSR(n) unsigned long n;
#       include "csrs.h"
#undef __CSR
};

extern bool enclave_mode;
