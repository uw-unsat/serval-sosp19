/*
 * Project Komodo
 * Copyright (c) Microsoft Corporation
 * All rights reserved.
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * Modified by the UNSAT group to port to RISC-V and for verification
 * using Serval, 2019.
 */

#include <asm/pmp.h>
#include <sys/string.h>
#include "monitor.h"

struct kom_pagedb_entry g_pagedb[KOM_SECURE_NPAGES];
uint64_t secure_pages[KOM_SECURE_NPAGES][KOM_PAGE_SIZE / sizeof(uint64_t)] __aligned(KOM_PAGE_SIZE);
extern uint64_t _payload_start[KOM_INSECURE_NPAGES][KOM_PAGE_SIZE / sizeof(uint64_t)];

struct host_state host_state;
bool enclave_mode;
kom_secure_pageno_t g_cur_dispatcher_pageno;

void init_monitor(void)
{
        enclave_mode = false;
        g_cur_dispatcher_pageno = 0;

        memset(g_pagedb, 0, sizeof(g_pagedb));
        memset(secure_pages, 0, sizeof(secure_pages));
        memset(&host_state, 0, sizeof(struct host_state));
}

static inline bool page_is_valid(kom_secure_pageno_t pageno)
{
        return pageno < KOM_SECURE_NPAGES;
}

static inline bool page_is_typed(kom_secure_pageno_t pageno, kom_pagetype_t type)
{
        return page_is_valid(pageno) && g_pagedb[pageno].type == type;
}

static inline bool page_is_free(kom_secure_pageno_t pageno)
{
        return page_is_typed(pageno, KOM_PAGE_FREE);
}

static inline void *page_monvaddr(kom_secure_pageno_t pageno)
{
        BUG_ON(!page_is_valid(pageno));
        return &secure_pages[pageno];
}

static inline uintptr_t page_paddr(kom_secure_pageno_t pageno)
{
        return (uintptr_t) page_monvaddr(pageno);
}

static inline void *insecure_page_monvaddr(kom_insecure_pageno_t pageno)
{
        return &_payload_start[pageno];
}

static inline uintptr_t insecure_page_paddr(kom_insecure_pageno_t pageno)
{
        return (uintptr_t) insecure_page_monvaddr(pageno);
}

static inline pgprot_t enclave_prot(uint64_t mapping)
{
        return __pgprot((mapping & KOM_MAPPING_RWX) | _PAGE_ENCLAVE);
}

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM)
static void enter_secure_world(kom_secure_pageno_t dispatcher_pageno)
{
        struct pt_regs *regs;
        struct kom_dispatcher *dispatcher;

        dispatcher = page_monvaddr(dispatcher_pageno);
        regs = current_pt_regs();
        copy_pt_regs(&host_state.regs, regs);

#define __CSR(n) host_state.n = csr_read(n);
#       include "csrs.h"
#undef __CSR

#define __CSR(n) csr_write(n, dispatcher->n);
#       include "csrs.h"
#undef __CSR

        /* enable access to secure pages */
        pmpcfg_write(pmp5cfg, PMPCFG_A_TOR | PMPCFG_R | PMPCFG_W | PMPCFG_X);

        /* disable access to satp */
        csr_set(mstatus, SR_TVM);

        /* Delegate no interrupts to enclave mode */
        csr_write(mideleg, 0);

        /* Delegate no exceptions */
        csr_write(medeleg, 0);

        local_flush_tlb_all();

        enclave_mode = true;
        g_cur_dispatcher_pageno = dispatcher_pageno;
}

static void leave_secure_world(bool entered)
{
        struct pt_regs *regs;
        struct kom_dispatcher *dispatcher;

        dispatcher = page_monvaddr(g_cur_dispatcher_pageno);
        dispatcher->entered = entered;

        regs = current_pt_regs();
        copy_pt_regs(&dispatcher->regs, regs);

#define __CSR(n) dispatcher->n = csr_read(n);
#       include "csrs.h"
#undef __CSR

#define __CSR(n) csr_write(n, host_state.n);
#       include "csrs.h"
#undef __CSR

        /* disable access to secure pages */
        pmpcfg_write(pmp5cfg, PMPCFG_A_TOR);

        /* enable access to satp */
        csr_clear(mstatus, SR_TVM);

        /* Enable interrupt delegation */
        csr_write(mideleg, IDEL_SOFT_S | IDEL_TIMER_S | IDEL_EXT_S);

        csr_write(medeleg, EDEL_BREAKPOINT | EDEL_ECALL_U |
                EDEL_INST_MISALIGNED | EDEL_INST_PAGE_FAULT |
                EDEL_LOAD_MISALIGNED | EDEL_LOAD_PAGE_FAULT |
                EDEL_STORE_MISALIGNED | EDEL_STORE_PAGE_FAULT);

        local_flush_tlb_all();

        enclave_mode = false;
        g_cur_dispatcher_pageno = 0;
}
#endif

static kom_err_t allocate_page(kom_secure_pageno_t page,
                               kom_secure_pageno_t addrspace_page,
                               kom_pagetype_t type)
{
        struct kom_addrspace *addrspace;

        if (!page_is_valid(page)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        if (!page_is_free(page)) {
                return KOM_ERR_PAGEINUSE;
        }

#if 0
        /* XXX: is this always true? */
        if (!page_is_typed(addrspace_page, KOM_PAGE_ADDRSPACE)) {
                return KOM_ERR_INVALID_ADDRSPACE;
        }
#endif

        addrspace = page_monvaddr(addrspace_page);

        if (addrspace->state != KOM_ADDRSPACE_INIT) {
                return KOM_ERR_ALREADY_FINAL;
        }

        /* Unlike Komodo, we always clear a new page. */
        memset(page_monvaddr(page), 0, KOM_PAGE_SIZE);

        g_pagedb[page].type = type;
        g_pagedb[page].addrspace_page = addrspace_page;
        addrspace->refcount++;

        return KOM_ERR_SUCCESS;
}

long kom_smc_query(void)
{
        return KOM_MAGIC;
}

long kom_smc_get_phys_pages(void)
{
        return KOM_SECURE_NPAGES;
}

kom_err_t kom_smc_init_addrspace(kom_secure_pageno_t addrspace_page,
                                 kom_secure_pageno_t l1pt_page)
{
        struct kom_addrspace *addrspace;

        if (addrspace_page == l1pt_page ||
            !(page_is_valid(addrspace_page) && page_is_valid(l1pt_page))) {
                return KOM_ERR_INVALID_PAGENO;
        }

        if (!(page_is_free(addrspace_page) && page_is_free(l1pt_page))) {
                return KOM_ERR_PAGEINUSE;
        }

        addrspace = page_monvaddr(addrspace_page);

        memset(addrspace, 0, KOM_PAGE_SIZE);
        memset(page_monvaddr(l1pt_page), 0, KOM_PAGE_SIZE);

        g_pagedb[addrspace_page].type = KOM_PAGE_ADDRSPACE;
        g_pagedb[addrspace_page].addrspace_page = addrspace_page;
        g_pagedb[l1pt_page].type = KOM_PAGE_L1PTABLE;
        g_pagedb[l1pt_page].addrspace_page = addrspace_page;

        addrspace->l1pt_page = l1pt_page;
        addrspace->refcount = 2; /* for the l1pt and addrspace itself */
        addrspace->state = KOM_ADDRSPACE_INIT;

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_init_dispatcher(kom_secure_pageno_t page,
                                  kom_secure_pageno_t addrspace_page,
                                  uintptr_t entrypoint)
{
        kom_err_t err;
        struct kom_addrspace *addrspace;
        struct kom_dispatcher *disp;

        if (!page_is_typed(addrspace_page, KOM_PAGE_ADDRSPACE)) {
                return KOM_ERR_INVALID_ADDRSPACE;
        }

        err = allocate_page(page, addrspace_page, KOM_PAGE_DISPATCHER);
        if (err != KOM_ERR_SUCCESS) {
                return err;
        }

        addrspace = page_monvaddr(addrspace_page);

        disp = page_monvaddr(page);
        disp->mepc = entrypoint;
        disp->satp = SATP_MODE_SV39 | PFN_DOWN(page_paddr(addrspace->l1pt_page));
        /* Enable S-mode interrupts in enclave mode */
        disp->sie = IE_SSIE | IE_STIE | IE_SEIE;


        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_init_l2ptable(kom_secure_pageno_t page,
                                kom_secure_pageno_t l1pt_page,
                                size_t l1_index)
{
        kom_err_t err;
        kom_secure_pageno_t addrspace_page;
        pgd_t *l1pt;

        if (l1_index >= PTRS_PER_PMD) {
                return KOM_ERR_INVALID_MAPPING;
        }

        if (!page_is_typed(l1pt_page, KOM_PAGE_L1PTABLE)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        l1pt = page_monvaddr(l1pt_page);
        if (pgd_val(l1pt[l1_index]) != 0) {
                return KOM_ERR_ADDRINUSE;
        }

        addrspace_page = g_pagedb[l1pt_page].addrspace_page;
        err = allocate_page(page, addrspace_page, KOM_PAGE_L2PTABLE);
        if (err != KOM_ERR_SUCCESS) {
                return err;
        }

        l1pt[l1_index] = pfn_pgd(PFN_DOWN(page_paddr(page)), __pgprot(_PAGE_TABLE));

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_init_l3ptable(kom_secure_pageno_t page,
                                kom_secure_pageno_t l2pt_page,
                                size_t l2_index)
{
        kom_err_t err;
        kom_secure_pageno_t addrspace_page;
        pmd_t *l2pt;

        if (l2_index >= PTRS_PER_PMD) {
                return KOM_ERR_INVALID_MAPPING;
        }

        if (!page_is_typed(l2pt_page, KOM_PAGE_L2PTABLE)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        l2pt = page_monvaddr(l2pt_page);
        if (pmd_val(l2pt[l2_index]) != 0) {
                return KOM_ERR_ADDRINUSE;
        }

        addrspace_page = g_pagedb[l2pt_page].addrspace_page;
        err = allocate_page(page, addrspace_page, KOM_PAGE_L3PTABLE);
        if (err != KOM_ERR_SUCCESS) {
                return err;
        }

        l2pt[l2_index] = pfn_pmd(PFN_DOWN(page_paddr(page)), __pgprot(_PAGE_TABLE));

        return KOM_ERR_SUCCESS;
}

static bool insecure_page_is_valid(kom_insecure_pageno_t pageno)
{
        return pageno < KOM_INSECURE_NPAGES;
}

kom_err_t kom_smc_map_secure(kom_secure_pageno_t page,
                             kom_secure_pageno_t l3pt_page,
                             size_t l3_index,
                             uint64_t mapping,
                             kom_insecure_pageno_t content)
{
        kom_err_t err;
        kom_secure_pageno_t addrspace_page;
        uint64_t *dst, *src;
        pte_t *l3pt;

        if (l3_index >= PTRS_PER_PTE) {
                return KOM_ERR_INVALID_MAPPING;
        }

        if (!insecure_page_is_valid(content)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        if (!page_is_typed(l3pt_page, KOM_PAGE_L3PTABLE)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        l3pt = page_monvaddr(l3pt_page);
        if (pte_val(l3pt[l3_index]) != 0) {
                return KOM_ERR_ADDRINUSE;
        }

        addrspace_page = g_pagedb[l3pt_page].addrspace_page;

        /* no check on mapping: we don't require R */

        err = allocate_page(page, addrspace_page, KOM_PAGE_DATA);
        if (err != KOM_ERR_SUCCESS) {
                return err;
        }

        /* no failures past this point! */

        l3pt[l3_index] = pfn_pte(PFN_DOWN(page_paddr(page)),
                                 enclave_prot(mapping));

        src = insecure_page_monvaddr(content);
        dst = page_monvaddr(page);
        memcpy(dst, src, SZ_4K);

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_map_insecure(kom_secure_pageno_t l3pt_page,
                               size_t l3_index,
                               uint64_t mapping,
                               kom_insecure_pageno_t insecure_pageno)
{
        struct kom_addrspace *addrspace;
        pte_t *l3pt;

        if (!insecure_page_is_valid(insecure_pageno)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        if (l3_index >= PTRS_PER_PTE) {
                return KOM_ERR_INVALID_MAPPING;
        }

        if (!page_is_typed(l3pt_page, KOM_PAGE_L3PTABLE)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        l3pt = page_monvaddr(l3pt_page);
        if (pte_val(l3pt[l3_index]) != 0) {
                return KOM_ERR_ADDRINUSE;
        }

        addrspace = page_monvaddr(g_pagedb[l3pt_page].addrspace_page);

        if (addrspace->state != KOM_ADDRSPACE_INIT) {
                return KOM_ERR_ALREADY_FINAL;
        }

        /* no check on mapping: we don't require R */

        /* no failures past this point! */

        l3pt[l3_index] = pfn_pte(PFN_DOWN(insecure_page_paddr(insecure_pageno)),
                                 enclave_prot(mapping));

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_remove(kom_secure_pageno_t pageno)
{
        struct kom_addrspace *addrspace;

#if IS_ENABLED(CONFIG_VERIFICATION_LLVM)
        if (enclave_mode)
                return KOM_ERR_ALREADY_ENTERED;
#endif

        if (!page_is_valid(pageno)) {
               return KOM_ERR_INVALID_PAGENO;
        }

        if (g_pagedb[pageno].type == KOM_PAGE_FREE) {
                return KOM_ERR_SUCCESS;
        }

        if (g_pagedb[pageno].type == KOM_PAGE_ADDRSPACE) {
                addrspace = page_monvaddr(pageno);
                if (addrspace->refcount != 1) {
                        return KOM_ERR_PAGEINUSE;
                }
                if (addrspace->state != KOM_ADDRSPACE_STOPPED) {
                        return KOM_ERR_NOT_STOPPED;
                }
        } else {
                addrspace = page_monvaddr(g_pagedb[pageno].addrspace_page);
                if (addrspace->state != KOM_ADDRSPACE_STOPPED) {
                        return KOM_ERR_NOT_STOPPED;
                }
        }

        /* we don't bother updating page tables etc., because once an
        * addrspace is stopped it can never execute again, so we can just
        * wait for them to be deleted */

        addrspace->refcount--;
        g_pagedb[pageno].type = KOM_PAGE_FREE;
        g_pagedb[pageno].addrspace_page = ~UINT64_C(0);

        return KOM_ERR_SUCCESS;
}


kom_err_t kom_smc_finalise(kom_secure_pageno_t addrspace_page)
{
        struct kom_addrspace *addrspace;

        if (!page_is_typed(addrspace_page, KOM_PAGE_ADDRSPACE)) {
                return KOM_ERR_INVALID_ADDRSPACE;
        }

        addrspace = page_monvaddr(addrspace_page);

        if (addrspace->state != KOM_ADDRSPACE_INIT) {
                return KOM_ERR_ALREADY_FINAL;
        }

        addrspace->state = KOM_ADDRSPACE_FINAL;
        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_stop(kom_secure_pageno_t addrspace_page)
{
        struct kom_addrspace *addrspace;

        if (!page_is_typed(addrspace_page, KOM_PAGE_ADDRSPACE)) {
                return KOM_ERR_INVALID_ADDRSPACE;
        }

        addrspace = page_monvaddr(addrspace_page);
        addrspace->state = KOM_ADDRSPACE_STOPPED;

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_enter(kom_secure_pageno_t disp_page, uintptr_t arg1,
                        uintptr_t arg2, uintptr_t arg3)
{
        struct kom_dispatcher *dispatcher;
        struct kom_addrspace *addrspace;

        if (!page_is_typed(disp_page, KOM_PAGE_DISPATCHER)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        dispatcher = page_monvaddr(disp_page);
        addrspace = page_monvaddr(g_pagedb[disp_page].addrspace_page);

        if (addrspace->state != KOM_ADDRSPACE_FINAL) {
                return KOM_ERR_NOT_FINAL;
        }

        if (dispatcher->entered) {
                return KOM_ERR_ALREADY_ENTERED;
        }

        dispatcher->regs.a0 = arg1;
        dispatcher->regs.a1 = arg2;
        dispatcher->regs.a2 = arg3;

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM)
        enter_secure_world(disp_page);
        mret_with_regs(&dispatcher->regs);
#endif

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_smc_resume(kom_secure_pageno_t disp_page)
{
        struct kom_dispatcher *dispatcher;
        struct kom_addrspace *addrspace;

        if (!page_is_typed(disp_page, KOM_PAGE_DISPATCHER)) {
                return KOM_ERR_INVALID_PAGENO;
        }

        dispatcher = page_monvaddr(disp_page);
        addrspace = page_monvaddr(g_pagedb[disp_page].addrspace_page);

        if (addrspace->state != KOM_ADDRSPACE_FINAL) {
                return KOM_ERR_NOT_FINAL;
        }

        if (!dispatcher->entered) {
                return KOM_ERR_NOT_ENTERED;
        }

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM)
        enter_secure_world(disp_page);
        mret_with_regs(&dispatcher->regs);
#endif

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_svc_exit(long exitvalue)
{
        struct pt_regs *regs;

        regs = &host_state.regs;
        regs->a0 = KOM_ERR_SUCCESS;
        regs->a1 = exitvalue;

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM)
        leave_secure_world(/* entered = */ false);
        mret_with_regs(regs);
#endif

        return KOM_ERR_SUCCESS;
}

kom_err_t kom_handle_trap(long cause)
{
        struct pt_regs *regs;

        regs = &host_state.regs;
        regs->a0 = cause < 0 ? KOM_ERR_INTERRUPTED : KOM_ERR_FAULT;
        regs->a1 = cause;

#if !IS_ENABLED(CONFIG_VERIFICATION_LLVM)
        leave_secure_world(/* entered = */ true);
        mret_with_regs(regs);
#endif

        return KOM_ERR_SUCCESS;
}
