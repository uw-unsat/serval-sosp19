#lang rosette/safe

(require
  serval/lib/core
  serval/spec/refcnt
  "state.rkt"
  (only-in racket/base struct-copy)
  (prefix-in komodo: "symbols.rkt")
  (prefix-in komodo: "generated/monitors/komodo/verif/asm-offsets.rkt")
)

(provide (all-defined-out))


(define pfn-secure_pages
  (bv (/ (car (find-symbol-by-name komodo:symbols 'secure_pages)) 4096) 64))

(define pfn-insecure_pages
  (bv (/ (car (find-symbol-by-name komodo:symbols '_payload_start)) 4096) 64))

(define (page->pfn page)
  (bvadd page pfn-secure_pages))

(define (insecure_page->pfn page)
  (bvadd page pfn-insecure_pages))


(define (pfn->pte pfn prot)
  (bvor (bvshl pfn (bv komodo:_PAGE_PFN_SHIFT 64)) prot))


(define (set-return! s val)
  (set-state-regs! s (struct-copy regs (state-regs s) [a0 (bv val 64)])))


(define (spec-kom_smc_query s)
  (set-return! s komodo:KOM_MAGIC))


(define (spec-kom_smc_get_phys_pages s)
  (set-return! s komodo:KOM_SECURE_NPAGES))


(define (spec-kom_smc_init_addrspace s addrspace_page l1pt_page)
  (cond
    [(bveq addrspace_page l1pt_page)
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (&& (page-valid? addrspace_page) (page-valid? l1pt_page)))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (&& (page-free? s addrspace_page) (page-free? s l1pt_page)))
      (set-return! s komodo:KOM_ERR_PAGEINUSE)]
    [else
      (update-state-pagedb.type! s addrspace_page (bv komodo:KOM_PAGE_ADDRSPACE 64))
      (update-state-pagedb.addrspace! s addrspace_page addrspace_page)
      (update-state-pagedb.type! s l1pt_page (bv komodo:KOM_PAGE_L1PTABLE 64))
      (update-state-pagedb.addrspace! s l1pt_page addrspace_page)

      (update-state-pages! s (list addrspace_page page-index-valid?) (bv 0 64))
      (update-state-addrspace.l1pt! s addrspace_page l1pt_page)
      (update-state-addrspace.refcount! s addrspace_page (bv 2 64))
      (update-state-addrspace.state! s addrspace_page (bv komodo:KOM_ADDRSPACE_INIT 64))

      (update-state-pages! s (list l1pt_page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-present! s (list l1pt_page pte-index-valid?) #f)
      (update-state-pgtable-pn! s (list l1pt_page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-perm! s (list l1pt_page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-secure! s (list l1pt_page pte-index-valid?) #f)

      (set-state-page-refcnt! s (incr-refcnt (state-page-refcnt s) addrspace_page addrspace_page))
      (set-state-page-refcnt! s (incr-refcnt (state-page-refcnt s) addrspace_page l1pt_page))

      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_init_dispatcher s page addrspace_page entrypoint)
  (cond
    [(! (page-typed? s addrspace_page komodo:KOM_PAGE_ADDRSPACE))
      (set-return! s komodo:KOM_ERR_INVALID_ADDRSPACE)]
    [(! (page-valid? page))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (page-free? s page))
      (set-return! s komodo:KOM_ERR_PAGEINUSE)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_INIT))
      (set-return! s komodo:KOM_ERR_ALREADY_FINAL)]
    [else
      (update-state-pagedb.type! s page (bv komodo:KOM_PAGE_DISPATCHER 64))
      (update-state-pagedb.addrspace! s page addrspace_page)

      (add1-state-addrspace.refcount! s addrspace_page)
      (set-state-page-refcnt! s (incr-refcnt (state-page-refcnt s) addrspace_page page))

      (update-state-pages! s (list page page-index-valid?) (bv 0 64))
      (update-state-dispatcher.mepc! s page entrypoint)
      (update-state-dispatcher.satp! s page (bvor (bv komodo:SATP_MODE_SV39 64)
                                                  (page->pfn (state-addrspace.l1pt s addrspace_page))))
      (update-state-dispatcher.sie! s page (bvor (bv komodo:IE_SEIE 64)
                                                 (bv komodo:IE_STIE 64)
                                                 (bv komodo:IE_SSIE 64)))

      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_init_l2ptable s page l1pt_page l1pt_index)
  (define addrspace_page ((state-pagedb.addrspace s) l1pt_page))
  (cond
    [(! (pte-index-valid? l1pt_index))
      (set-return! s komodo:KOM_ERR_INVALID_MAPPING)]
    [(! (page-typed? s l1pt_page komodo:KOM_PAGE_L1PTABLE))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (bvzero? ((state-pages s) l1pt_page l1pt_index)))
      (set-return! s komodo:KOM_ERR_ADDRINUSE)]
    [(! (page-valid? page))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (page-free? s page))
      (set-return! s komodo:KOM_ERR_PAGEINUSE)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_INIT))
      (set-return! s komodo:KOM_ERR_ALREADY_FINAL)]
    [else
      (update-state-pagedb.type! s page (bv komodo:KOM_PAGE_L2PTABLE 64))
      (update-state-pagedb.addrspace! s page addrspace_page)

      (update-state-pages! s (list page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-pn! s (list page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-present! s (list page pte-index-valid?) #f)
      (update-state-pgtable-perm! s (list page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-secure! s (list page pte-index-valid?) #f)

      (add1-state-addrspace.refcount! s addrspace_page)
      (set-state-page-refcnt! s (incr-refcnt (state-page-refcnt s) addrspace_page page))

      (update-state-pages! s (list l1pt_page l1pt_index) (pfn->pte (page->pfn page) (bv komodo:_PAGE_TABLE 64)))
      (update-state-pgtable-pn! s (list l1pt_page l1pt_index) page)
      (update-state-pgtable-present! s (list l1pt_page l1pt_index) #t)

      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_init_l3ptable s page l2pt_page l2pt_index)
  (define addrspace_page ((state-pagedb.addrspace s) l2pt_page))
  (cond
    [(! (pte-index-valid? l2pt_index))
      (set-return! s komodo:KOM_ERR_INVALID_MAPPING)]
    [(! (page-typed? s l2pt_page komodo:KOM_PAGE_L2PTABLE))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (bvzero? ((state-pages s) l2pt_page l2pt_index)))
      (set-return! s komodo:KOM_ERR_ADDRINUSE)]
    [(! (page-valid? page))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (page-free? s page))
      (set-return! s komodo:KOM_ERR_PAGEINUSE)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_INIT))
      (set-return! s komodo:KOM_ERR_ALREADY_FINAL)]
    [else
      (update-state-pagedb.type! s page (bv komodo:KOM_PAGE_L3PTABLE 64))
      (update-state-pagedb.addrspace! s page addrspace_page)

      (update-state-pages! s (list page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-pn! s (list page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-present! s (list page pte-index-valid?) #f)
      (update-state-pgtable-perm! s (list page pte-index-valid?) (bv 0 64))
      (update-state-pgtable-secure! s (list page pte-index-valid?) #f)


      (add1-state-addrspace.refcount! s addrspace_page)
      (set-state-page-refcnt! s (incr-refcnt (state-page-refcnt s) addrspace_page page))

      (define entry (pfn->pte (page->pfn page) (bv komodo:_PAGE_TABLE 64)))
      (update-state-pages! s (list l2pt_page l2pt_index) entry)
      (update-state-pgtable-pn! s (list l2pt_page l2pt_index) page)
      (update-state-pgtable-present! s (list l2pt_page l2pt_index) #t)

      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_map_secure s page l3pt_page l3pt_index mapping content)
  (define addrspace_page ((state-pagedb.addrspace s) l3pt_page))
  (cond
    [(! (pte-index-valid? l3pt_index))
      (set-return! s komodo:KOM_ERR_INVALID_MAPPING)]
    [(|| (! (insecure-page-valid? content)) (! (page-typed? s l3pt_page komodo:KOM_PAGE_L3PTABLE)))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (bvzero? ((state-pages s) l3pt_page l3pt_index)))
      (set-return! s komodo:KOM_ERR_ADDRINUSE)]
    [(! (page-valid? page))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (page-free? s page))
      (set-return! s komodo:KOM_ERR_PAGEINUSE)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_INIT))
      (set-return! s komodo:KOM_ERR_ALREADY_FINAL)]
    [else
      (update-state-pagedb.type! s page (bv komodo:KOM_PAGE_DATA 64))
      (update-state-pagedb.addrspace! s page addrspace_page)

      (update-state-pages! s (list page pte-index-valid?) (bv 0 64))

      (add1-state-addrspace.refcount! s addrspace_page)
      (set-state-page-refcnt! s (incr-refcnt (state-page-refcnt s) addrspace_page page))

      (define entry (pfn->pte (page->pfn page) (enclave-prot mapping)))
      (update-state-pages! s (list l3pt_page l3pt_index) entry)
      (update-state-pgtable-pn! s (list l3pt_page l3pt_index) page)
      (update-state-pgtable-present! s (list l3pt_page l3pt_index) #t)
      (update-state-pgtable-perm! s (list l3pt_page l3pt_index) mapping)
      (update-state-pgtable-secure! s (list l3pt_page l3pt_index) #t)

      (define old-pages (state-pages s))
      (define old-insecure-pages (state-insecure-pages s))

      (set-state-pages! s
        (lambda (pageno idx)
          (cond
            [(&& (equal? pageno page) (bvult idx (bv 512 64)))
              (old-insecure-pages content idx)]
            [else (old-pages pageno idx)])))

      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_map_insecure s l3pt_page l3pt_index mapping insecure_pageno)
  (define addrspace_page ((state-pagedb.addrspace s) l3pt_page))
  (cond
    [(! (insecure-page-valid? insecure_pageno))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (pte-index-valid? l3pt_index))
      (set-return! s komodo:KOM_ERR_INVALID_MAPPING)]
    [(! (page-typed? s l3pt_page komodo:KOM_PAGE_L3PTABLE))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (bvzero? ((state-pages s) l3pt_page l3pt_index)))
      (set-return! s komodo:KOM_ERR_ADDRINUSE)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_INIT))
      (set-return! s komodo:KOM_ERR_ALREADY_FINAL)]
    [else
      (define entry (pfn->pte (insecure_page->pfn insecure_pageno) (enclave-prot mapping)))
      (update-state-pages! s (list l3pt_page l3pt_index) entry)
      (update-state-pgtable-pn! s (list l3pt_page l3pt_index) insecure_pageno)
      (update-state-pgtable-present! s (list l3pt_page l3pt_index) #t)
      (update-state-pgtable-perm! s (list l3pt_page l3pt_index) mapping)
      (update-state-pgtable-secure! s (list l3pt_page l3pt_index) #f)


      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_remove s page)
  (define addrspace_page ((state-pagedb.addrspace s) page))
  (cond
    [(state-enclave-mode s)
      (set-return! s komodo:KOM_ERR_ALREADY_ENTERED)]
    [(! (page-valid? page))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(page-free? s page)
      (set-return! s komodo:KOM_ERR_SUCCESS)]
    ; ; page is addrspace with non-zero refcount
    [(&& (page-typed? s page komodo:KOM_PAGE_ADDRSPACE)
         (! (bveq (state-addrspace.refcount s page) (bv 1 64))))
      (set-return! s komodo:KOM_ERR_PAGEINUSE)]
    [(&& (page-typed? s page komodo:KOM_PAGE_ADDRSPACE)
         (! (addrspace-state? s page komodo:KOM_ADDRSPACE_STOPPED)))
      (set-return! s komodo:KOM_ERR_NOT_STOPPED)]
    ; page is not addrspace and its addrspace is not stopped
    [(&& (! (page-typed? s page komodo:KOM_PAGE_ADDRSPACE))
         (! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_STOPPED)))
      (set-return! s komodo:KOM_ERR_NOT_STOPPED)]
    [else
      (sub1-state-addrspace.refcount! s addrspace_page)
      (set-state-page-refcnt! s (decr-refcnt (state-page-refcnt s) addrspace_page page))

      (update-state-pagedb.type! s page (bv komodo:KOM_PAGE_FREE 64))
      (update-state-pagedb.addrspace! s page (bv -1 64))

      (update-state-pgtable-present! s (list page page-index-valid?) #f)
      (update-state-pgtable-pn! s (list page page-index-valid?) (bv 0 64))
      (update-state-pgtable-perm! s (list page page-index-valid?) (bv 0 64))
      (update-state-pgtable-secure! s (list page page-index-valid?) #f)

      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_finalise s addrspace_page)
  (cond
    [(! (page-typed? s addrspace_page komodo:KOM_PAGE_ADDRSPACE))
      (set-return! s komodo:KOM_ERR_INVALID_ADDRSPACE)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_INIT))
      (set-return! s komodo:KOM_ERR_ALREADY_FINAL)]
    [else
      (update-state-addrspace.state! s addrspace_page (bv komodo:KOM_ADDRSPACE_FINAL 64))

      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define (spec-kom_smc_stop s addrspace_page)
  (cond
    [(! (page-typed? s addrspace_page komodo:KOM_PAGE_ADDRSPACE))
      (set-return! s komodo:KOM_ERR_INVALID_ADDRSPACE)]
    [else
      (update-state-addrspace.state! s addrspace_page (bv komodo:KOM_ADDRSPACE_STOPPED 64))

      (set-return! s komodo:KOM_ERR_SUCCESS)]))

(define (spec-enter_secure_world s dispatcher-pageno)

  (set-state-enclave-mode! s #t)
  (set-state-current-dispatcher! s dispatcher-pageno)
  (set-state-current-addrspace! s ((state-pagedb.addrspace s) dispatcher-pageno))

  (set-state-host-state! s (state-regs s))

  (set-state-regs! s (struct-copy regs (state-regs s)
    [ra (state-dispatcher.regs.ra s dispatcher-pageno)]
    [sp (state-dispatcher.regs.sp s dispatcher-pageno)]
    [gp (state-dispatcher.regs.gp s dispatcher-pageno)]
    [tp (state-dispatcher.regs.tp s dispatcher-pageno)]

    [a0 (state-dispatcher.regs.a0 s dispatcher-pageno)]
    [a1 (state-dispatcher.regs.a1 s dispatcher-pageno)]
    [a2 (state-dispatcher.regs.a2 s dispatcher-pageno)]
    [a3 (state-dispatcher.regs.a3 s dispatcher-pageno)]
    [a4 (state-dispatcher.regs.a4 s dispatcher-pageno)]
    [a5 (state-dispatcher.regs.a5 s dispatcher-pageno)]
    [a6 (state-dispatcher.regs.a6 s dispatcher-pageno)]
    [a7 (state-dispatcher.regs.a7 s dispatcher-pageno)]

    [s0 (state-dispatcher.regs.s0 s dispatcher-pageno)]
    [s1 (state-dispatcher.regs.s1 s dispatcher-pageno)]
    [s2 (state-dispatcher.regs.s2 s dispatcher-pageno)]
    [s3 (state-dispatcher.regs.s3 s dispatcher-pageno)]
    [s4 (state-dispatcher.regs.s4 s dispatcher-pageno)]
    [s5 (state-dispatcher.regs.s5 s dispatcher-pageno)]
    [s6 (state-dispatcher.regs.s6 s dispatcher-pageno)]
    [s7 (state-dispatcher.regs.s7 s dispatcher-pageno)]
    [s8 (state-dispatcher.regs.s8 s dispatcher-pageno)]
    [s9 (state-dispatcher.regs.s9 s dispatcher-pageno)]
    [s10 (state-dispatcher.regs.s10 s dispatcher-pageno)]
    [s11 (state-dispatcher.regs.s11 s dispatcher-pageno)]

    [t0 (state-dispatcher.regs.t0 s dispatcher-pageno)]
    [t1 (state-dispatcher.regs.t1 s dispatcher-pageno)]
    [t2 (state-dispatcher.regs.t2 s dispatcher-pageno)]
    [t3 (state-dispatcher.regs.t3 s dispatcher-pageno)]
    [t4 (state-dispatcher.regs.t4 s dispatcher-pageno)]
    [t5 (state-dispatcher.regs.t5 s dispatcher-pageno)]
    [t6 (state-dispatcher.regs.t6 s dispatcher-pageno)]

    [mepc (state-dispatcher.mepc s dispatcher-pageno)]
    [satp (state-dispatcher.satp s dispatcher-pageno)]
    [stvec (state-dispatcher.stvec s dispatcher-pageno)]
    [scounteren (state-dispatcher.scounteren s dispatcher-pageno)]
    [stval (state-dispatcher.stval s dispatcher-pageno)]
    [sip (state-dispatcher.sip s dispatcher-pageno)]
    [scause (state-dispatcher.scause s dispatcher-pageno)]
    [sepc (state-dispatcher.sepc s dispatcher-pageno)]
    [sstatus (state-dispatcher.sstatus s dispatcher-pageno)]
    [sscratch (state-dispatcher.sscratch s dispatcher-pageno)]
    [sie (state-dispatcher.sie s dispatcher-pageno)]
  ))

)

(define (spec-kom_smc_enter s disp_page a0 a1 a2)
  (define addrspace_page ((state-pagedb.addrspace s) disp_page))
  (cond
    [(! (page-typed? s disp_page komodo:KOM_PAGE_DISPATCHER))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_FINAL))
      (set-return! s komodo:KOM_ERR_NOT_FINAL)]
    [(! (bvzero? (state-dispatcher.entered s disp_page)))
      (set-return! s komodo:KOM_ERR_ALREADY_ENTERED)]
    [else
      (update-state-dispatcher.regs.a0! s disp_page a0)
      (update-state-dispatcher.regs.a1! s disp_page a1)
      (update-state-dispatcher.regs.a2! s disp_page a2)

      (spec-enter_secure_world s disp_page)]))


(define (spec-kom_smc_resume s disp_page)
  (define addrspace_page ((state-pagedb.addrspace s) disp_page))
  (cond
    [(! (page-typed? s disp_page komodo:KOM_PAGE_DISPATCHER))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_FINAL))
      (set-return! s komodo:KOM_ERR_NOT_FINAL)]
    [(bvzero? (state-dispatcher.entered s disp_page))
      (set-return! s komodo:KOM_ERR_NOT_ENTERED)]
    [else
      (spec-enter_secure_world s disp_page)]))

(define (leave_secure_world s dispatcher_pageno entered)

  (define cur-regs (state-regs s))

  (if entered
    (update-state-dispatcher.entered! s dispatcher_pageno (bv 1 64))
    (update-state-dispatcher.entered! s dispatcher_pageno (bv 0 64)))

  (update-state-dispatcher.regs.ra! s dispatcher_pageno (regs-ra cur-regs))
  (update-state-dispatcher.regs.sp! s dispatcher_pageno (regs-sp cur-regs))
  (update-state-dispatcher.regs.gp! s dispatcher_pageno (regs-gp cur-regs))
  (update-state-dispatcher.regs.tp! s dispatcher_pageno (regs-tp cur-regs))

  (update-state-dispatcher.regs.a0! s dispatcher_pageno (regs-a0 cur-regs))
  (update-state-dispatcher.regs.a1! s dispatcher_pageno (regs-a1 cur-regs))
  (update-state-dispatcher.regs.a2! s dispatcher_pageno (regs-a2 cur-regs))
  (update-state-dispatcher.regs.a3! s dispatcher_pageno (regs-a3 cur-regs))
  (update-state-dispatcher.regs.a4! s dispatcher_pageno (regs-a4 cur-regs))
  (update-state-dispatcher.regs.a5! s dispatcher_pageno (regs-a5 cur-regs))
  (update-state-dispatcher.regs.a6! s dispatcher_pageno (regs-a6 cur-regs))
  (update-state-dispatcher.regs.a7! s dispatcher_pageno (regs-a7 cur-regs))

  (update-state-dispatcher.regs.s0! s dispatcher_pageno (regs-s0 cur-regs))
  (update-state-dispatcher.regs.s1! s dispatcher_pageno (regs-s1 cur-regs))
  (update-state-dispatcher.regs.s2! s dispatcher_pageno (regs-s2 cur-regs))
  (update-state-dispatcher.regs.s3! s dispatcher_pageno (regs-s3 cur-regs))
  (update-state-dispatcher.regs.s4! s dispatcher_pageno (regs-s4 cur-regs))
  (update-state-dispatcher.regs.s5! s dispatcher_pageno (regs-s5 cur-regs))
  (update-state-dispatcher.regs.s6! s dispatcher_pageno (regs-s6 cur-regs))
  (update-state-dispatcher.regs.s7! s dispatcher_pageno (regs-s7 cur-regs))
  (update-state-dispatcher.regs.s8! s dispatcher_pageno (regs-s8 cur-regs))
  (update-state-dispatcher.regs.s9! s dispatcher_pageno (regs-s9 cur-regs))
  (update-state-dispatcher.regs.s10! s dispatcher_pageno (regs-s10 cur-regs))
  (update-state-dispatcher.regs.s11! s dispatcher_pageno (regs-s11 cur-regs))

  (update-state-dispatcher.regs.t0! s dispatcher_pageno (regs-t0 cur-regs))
  (update-state-dispatcher.regs.t1! s dispatcher_pageno (regs-t1 cur-regs))
  (update-state-dispatcher.regs.t2! s dispatcher_pageno (regs-t2 cur-regs))
  (update-state-dispatcher.regs.t3! s dispatcher_pageno (regs-t3 cur-regs))
  (update-state-dispatcher.regs.t4! s dispatcher_pageno (regs-t4 cur-regs))
  (update-state-dispatcher.regs.t5! s dispatcher_pageno (regs-t5 cur-regs))
  (update-state-dispatcher.regs.t6! s dispatcher_pageno (regs-t6 cur-regs))

  (update-state-dispatcher.mepc! s dispatcher_pageno (regs-mepc cur-regs))
  (update-state-dispatcher.satp! s dispatcher_pageno (regs-satp cur-regs))
  (update-state-dispatcher.stvec! s dispatcher_pageno (regs-stvec cur-regs))
  (update-state-dispatcher.scounteren! s dispatcher_pageno (regs-scounteren cur-regs))
  (update-state-dispatcher.stval! s dispatcher_pageno (regs-stval cur-regs))
  (update-state-dispatcher.sip! s dispatcher_pageno (regs-sip cur-regs))
  (update-state-dispatcher.scause! s dispatcher_pageno (regs-scause cur-regs))
  (update-state-dispatcher.sepc! s dispatcher_pageno (regs-sepc cur-regs))
  (update-state-dispatcher.sstatus! s dispatcher_pageno (regs-sstatus cur-regs))
  (update-state-dispatcher.sscratch! s dispatcher_pageno (regs-sscratch cur-regs))
  (update-state-dispatcher.sie! s dispatcher_pageno (regs-sie cur-regs))

  (set-state-regs! s (state-host-state s))
  (set-state-current-dispatcher! s (bv 0 64))
  (set-state-enclave-mode! s #f)
)

(define (spec-kom_handle_trap s cause)
  (when (state-enclave-mode s)
    (set-state-host-state! s (struct-copy regs (state-host-state s)
      [a0 (if (bvslt cause (bv 0 64))
              (bv komodo:KOM_ERR_INTERRUPTED 64)
              (bv komodo:KOM_ERR_FAULT 64))]
      [a1 cause]))
    (define cur-dispatcher (state-current-dispatcher s))
    (leave_secure_world s cur-dispatcher #t)))

(define (spec-kom_svc_exit s exitvalue)
  (define newmepc (bvadd (bv 4 64) (regs-mepc (state-regs s))))
  (set-state-regs! s (struct-copy regs (state-regs s) [mepc newmepc]))
  (cond
    [(! (state-enclave-mode s)) (set-return! s (- komodo:ENOSYS))]
    [else
      (set-state-host-state! s (struct-copy regs (state-host-state s)
        [a0 (bv 0 64)]
        [a1 exitvalue]))

      (define cur-dispatcher (state-current-dispatcher s))
      (leave_secure_world s cur-dispatcher #f)

    ]))

(define (spec-kom_enosys s)
  (define newmepc (bvadd (bv 4 64) (regs-mepc (state-regs s))))
  (set-state-regs! s (struct-copy regs (state-regs s) [mepc newmepc]))
  (set-return! s (- komodo:ENOSYS)))

(define (make-smc-spec spec)
  (lambda (state . args)
    (define newmepc (bvadd (bv 4 64) (regs-mepc (state-regs state))))
    (set-state-regs! state (struct-copy regs (state-regs state) [mepc newmepc]))
    (cond
      [(state-enclave-mode state) (set-return! state (- komodo:ENOSYS))]
      [else (apply spec state args)])))

(define (enclave-pgwalk-secure s l1pt_index l2pt_index l3pt_index)
  (define (pgtable-pn pageno index)
    ((state-pgtable-pn s) pageno index))
  (define (pgtable-secure pageno index)
    ((state-pgtable-secure s) pageno index))
  (define (pgtable-present pageno index)
    ((state-pgtable-present s) pageno index))

  (define l1pt_page (state-addrspace.l1pt s (state-current-addrspace s)))

  (define l2pt_present (pgtable-present l1pt_page l1pt_index))
  (define l2pt_page (pgtable-pn l1pt_page l1pt_index))

  (define l3pt_present (pgtable-present l2pt_page l2pt_index))
  (define l3pt_page (pgtable-pn l2pt_page l2pt_index))

  (define data_present (pgtable-present l3pt_page l3pt_index))
  (define data_secure (pgtable-secure l3pt_page l3pt_index))
  (define data_page (pgtable-pn l3pt_page l3pt_index))

  (define ok
    (&& (page-index-valid? l1pt_index)
        (page-index-valid? l2pt_index)
        (page-index-valid? l3pt_index)
        l2pt_present
        l3pt_present
        data_present
        data_secure))

  (cons ok data_page))

(define (spec-enclave_read s page offset)
  (when (&& (state-enclave-mode s)
            (page-valid? page)
            (page-index-valid? offset)
            (page-typed? s page komodo:KOM_PAGE_DATA)
            (bveq ((state-pagedb.addrspace s) page) (state-current-addrspace s)))
    (define value ((state-pages s) page offset))
    (set-state-regs! s (struct-copy regs (state-regs s) [a0 value]))))

(define (spec-enclave_write s page offset value)
  (when (&& (state-enclave-mode s)
            (page-valid? page)
            (page-index-valid? offset)
            (page-typed? s page komodo:KOM_PAGE_DATA)
            (bveq ((state-pagedb.addrspace s) page) (state-current-addrspace s)))
    (update-state-pages! s (list page offset) value)))

(define (spec-insecure_read s page offset)
  (when (&& (insecure-page-valid? page)
            (page-index-valid? offset))
    (define value ((state-insecure-pages s) page offset))
    (set-state-regs! s (struct-copy regs (state-regs s) [a0 value]))))

(define (spec-insecure_write s page offset value)
  (when (&& (insecure-page-valid? page)
            (page-index-valid? offset))
    (update-state-insecure-pages! s (list page offset) value)))

(define-syntax-rule (expand-spec-tests form)
  (begin
    (form "enclave_write" spec-enclave_write (list (make-bv64) (make-bv64) (make-bv64)))
    (form "enclave_read" spec-enclave_read (list (make-bv64) (make-bv64)))
    (form "insecure_write" spec-insecure_write (list (make-bv64) (make-bv64) (make-bv64)))
    (form "insecure_read" spec-insecure_read (list (make-bv64) (make-bv64)))
    (form "kom_smc_query" (make-smc-spec spec-kom_smc_query) null)
    (form "kom_smc_get_phys_pages" (make-smc-spec spec-kom_smc_get_phys_pages) null)
    (form "kom_smc_init_addrspace" (make-smc-spec spec-kom_smc_init_addrspace) (list (make-bv64) (make-bv64)))
    (form "kom_smc_init_dispatcher" (make-smc-spec spec-kom_smc_init_dispatcher) (list (make-bv64) (make-bv64) (make-bv64)))
    (form "kom_smc_init_l2ptable" (make-smc-spec spec-kom_smc_init_l2ptable) (list (make-bv64) (make-bv64) (make-bv64)))
    (form "kom_smc_init_l3ptable" (make-smc-spec spec-kom_smc_init_l3ptable) (list (make-bv64) (make-bv64) (make-bv64)))
    (form "kom_smc_map_secure" (make-smc-spec spec-kom_smc_map_secure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64)))
    (form "kom_smc_map_insecure" (make-smc-spec spec-kom_smc_map_insecure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64)))
    (form "kom_smc_remove" (make-smc-spec spec-kom_smc_remove) (list (make-bv64)))
    (form "kom_smc_finalise" (make-smc-spec spec-kom_smc_finalise) (list (make-bv64)))
    (form "kom_smc_stop" (make-smc-spec spec-kom_smc_stop) (list (make-bv64)))
    (form "kom_smc_enter" (make-smc-spec spec-kom_smc_enter) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64)))
    (form "kom_smc_resume" (make-smc-spec spec-kom_smc_resume) (list (make-bv64)))
    (form "kom_svc_exit" spec-kom_svc_exit (list (make-bv64)))
  ))
