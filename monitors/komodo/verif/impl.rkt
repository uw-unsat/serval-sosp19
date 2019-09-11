#lang rosette/safe

(require
  "state.rkt"
  serval/lib/core
  serval/spec/refcnt
  (prefix-in riscv: serval/riscv/objdump)
  (prefix-in komodo: "generated/monitors/komodo/verif/asm-offsets.rkt")
)

(provide (all-defined-out))


(define (offset->index offset)
  (bvpointer (/ offset 8)))

(define (mregions-abstract mregions)
  (define block-pagedb (find-block-by-name mregions 'g_pagedb))
  (define block-pages (find-block-by-name mregions 'secure_pages))
  (define block-enclave-mode (find-block-by-name mregions 'enclave_mode))
  (define block-host-state (find-block-by-name mregions 'host_state))
  (define block-current-dispatcher (find-block-by-name mregions 'g_cur_dispatcher_pageno))
  (define block-insecure-pages (find-block-by-name mregions '_payload_start))

  (define enclave-mode-i8 (mblock-iload block-enclave-mode null))
  (define enclave-mode (if (bveq enclave-mode-i8 (bv 0 8)) #f #t))

  (define current-dispatcher (mblock-iload block-current-dispatcher null))

  (define host-state
   (regs
    (mblock-iload block-host-state (list 'regs 'ra))
    (mblock-iload block-host-state (list 'regs 'sp))
    (mblock-iload block-host-state (list 'regs 'gp))
    (mblock-iload block-host-state (list 'regs 'tp))
    (mblock-iload block-host-state (list 'regs 't0))
    (mblock-iload block-host-state (list 'regs 't1))
    (mblock-iload block-host-state (list 'regs 't2))
    (mblock-iload block-host-state (list 'regs 's0))
    (mblock-iload block-host-state (list 'regs 's1))
    (mblock-iload block-host-state (list 'regs 'a0))
    (mblock-iload block-host-state (list 'regs 'a1))
    (mblock-iload block-host-state (list 'regs 'a2))
    (mblock-iload block-host-state (list 'regs 'a3))
    (mblock-iload block-host-state (list 'regs 'a4))
    (mblock-iload block-host-state (list 'regs 'a5))
    (mblock-iload block-host-state (list 'regs 'a6))
    (mblock-iload block-host-state (list 'regs 'a7))
    (mblock-iload block-host-state (list 'regs 's2))
    (mblock-iload block-host-state (list 'regs 's3))
    (mblock-iload block-host-state (list 'regs 's4))
    (mblock-iload block-host-state (list 'regs 's5))
    (mblock-iload block-host-state (list 'regs 's6))
    (mblock-iload block-host-state (list 'regs 's7))
    (mblock-iload block-host-state (list 'regs 's8))
    (mblock-iload block-host-state (list 'regs 's9))
    (mblock-iload block-host-state (list 'regs 's10))
    (mblock-iload block-host-state (list 'regs 's11))
    (mblock-iload block-host-state (list 'regs 't3))
    (mblock-iload block-host-state (list 'regs 't4))
    (mblock-iload block-host-state (list 'regs 't5))
    (mblock-iload block-host-state (list 'regs 't6))
    (mblock-iload block-host-state (list 'satp))
    (mblock-iload block-host-state (list 'scause))
    (mblock-iload block-host-state (list 'scounteren))
    (mblock-iload block-host-state (list 'sepc))
    (mblock-iload block-host-state (list 'sscratch))
    (mblock-iload block-host-state (list 'sstatus))
    (mblock-iload block-host-state (list 'stvec))
    (mblock-iload block-host-state (list 'stval))
    (mblock-iload block-host-state (list 'mepc))
    (mblock-iload block-host-state (list 'sip))
    (mblock-iload block-host-state (list 'sie))
   ))

  (define page-refcnt (make-havoc-refcnt))
  (define-symbolic* current-addrspace (bitvector 64))
  (define-symbolic* pgtable-pn pgtable-perm (~> (bitvector 64) (bitvector 64) (bitvector 64)))
  (define-symbolic* pgtable-present pgtable-secure (~> (bitvector 64) (bitvector 64) boolean?))

         ; regs
  (state (zero-regs)
         ; pagedb.type
         (lambda (pageno)
           (mblock-iload block-pagedb (list pageno 'type)))
         ; pagedb.addrspace
         (lambda (pageno)
           (mblock-iload block-pagedb (list pageno 'addrspace_page)))
         ; pages
         (lambda (pageno index)
           (mblock-iload block-pages (list pageno index)))
         ; insecure pages
         (lambda (pageno index)
           (mblock-iload block-insecure-pages (list pageno index)))
         enclave-mode
         host-state
         current-dispatcher
         current-addrspace
         page-refcnt
         pgtable-pn
         pgtable-present
         pgtable-perm
         pgtable-secure))


(define (mregions-invariants mregions)
  (define block-pagedb (find-block-by-name mregions 'g_pagedb))
  (define block-pages (find-block-by-name mregions 'secure_pages))
  (define block-host-state (find-block-by-name mregions 'host_state))
  (define block-current-dispatcher (find-block-by-name mregions 'g_cur_dispatcher_pageno))
  (define block-enclave-mode (find-block-by-name mregions 'enclave_mode))

  (define enclave-mode-i8 (mblock-iload block-enclave-mode null))
  (define enclave-mode (if (bveq enclave-mode-i8 (bv 0 8)) #f #t))

  (define current-dispatcher (mblock-iload block-current-dispatcher null))

  (define (pageno->pagedb.type pageno)
    (mblock-iload block-pagedb (list pageno 'type)))

  (define (pageno->pagedb.addrspace_page pageno)
    (mblock-iload block-pagedb (list pageno 'addrspace_page)))

  (define (pageno->addrspace.l1pt_page pageno)
    (mblock-iload block-pages (list pageno (offset->index komodo:KOM_ADDRSPACE_L1PT_PAGE))))

  (define (pageno->dispatcher.sie pageno)
    (mblock-iload block-pages (list pageno (bvpointer komodo:KOM_DISPATCHER_SIE))))
  (define (pageno->dispatcher.sip pageno)
    (mblock-iload block-pages (list pageno (bvpointer komodo:KOM_DISPATCHER_SIP))))
  (define (pageno->dispatcher.sstatus pageno)
    (mblock-iload block-pages (list pageno (bvpointer komodo:KOM_DISPATCHER_SSTATUS))))

  (define (impl-page-typed? pageno type)
    (&& (page-valid? pageno)
        (bveq (pageno->pagedb.type pageno) (bv type 64))))

  (define (impl-page-nonfree? pageno)
    (&& (page-valid? pageno)
        (! (bveq (pageno->pagedb.type pageno) (bv komodo:KOM_PAGE_FREE 64)))))

  (define-symbolic pageno (bitvector 64))

  ; Use page-valid? only here, as using types complicates the RI (esp. for remove).
  (&&
    ; pagedb[pageno].addrspace_page is valid if pageno is not free
    (forall (list pageno)
            (=> (impl-page-nonfree? pageno)
                (page-valid? (pageno->pagedb.addrspace_page pageno))))
    ; addrspace.l1pt_page is valid
    (forall (list pageno)
            (=> (impl-page-typed? pageno komodo:KOM_PAGE_ADDRSPACE)
                (page-valid? (pageno->addrspace.l1pt_page pageno))))
    (forall (list pageno)
            (=> (impl-page-typed? pageno komodo:KOM_PAGE_ADDRSPACE)
                (bveq pageno (pageno->pagedb.addrspace_page pageno))))
    (forall (list pageno)
            (=> (impl-page-typed? pageno komodo:KOM_PAGE_DISPATCHER)
                (&&
                  (bveq (bvand (bvnot riscv:sstatus-mask) (pageno->dispatcher.sstatus pageno)) (bv 0 64))
                  (bveq (bvand (bvnot riscv:sie-mask) (pageno->dispatcher.sie pageno)) (bv 0 64))
                  (bveq (bvand (bvnot riscv:sip-mask) (pageno->dispatcher.sip pageno)) (bv 0 64)))))

    (page-valid? current-dispatcher)
    (=> enclave-mode
      (impl-page-typed? current-dispatcher komodo:KOM_PAGE_DISPATCHER))
    (bveq (bvand (bvnot riscv:sstatus-mask) (mblock-iload block-host-state (list 'sstatus))) (bv 0 64))
    (bveq (bvand (bvnot riscv:sie-mask) (mblock-iload block-host-state (list 'sie))) (bv 0 64))
    (bveq (bvand (bvnot riscv:sip-mask) (mblock-iload block-host-state (list 'sip))) (bv 0 64))
))
