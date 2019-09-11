#lang rosette/safe

(require
  serval/lib/core
  serval/riscv/spec
  serval/spec/refcnt
  (prefix-in komodo: "generated/monitors/komodo/verif/asm-offsets.rkt"))

(provide
  (all-defined-out)
  (all-from-out serval/riscv/spec))

(struct state (regs
               pagedb.type
               pagedb.addrspace
               pages
               insecure-pages
               enclave-mode
               host-state
               current-dispatcher
               current-addrspace
               page-refcnt
               pgtable-pn
               pgtable-present
               pgtable-perm
               pgtable-secure
              )
  #:transparent #:mutable
  #:methods gen:equal+hash
  [(define (equal-proc s t equal?-recur)
     (define-symbolic pageno index (bitvector 64))
     (&& (equal?-recur (state-regs s) (state-regs t))
         (equal?-recur (state-host-state s) (state-host-state t))
         (equal?-recur (state-current-dispatcher s) (state-current-dispatcher t))
         (equal?-recur (state-enclave-mode s) (state-enclave-mode t))
         ; pagedb
         (forall (list pageno)
                 (=> (page-valid? pageno)
                     (&& (bveq ((state-pagedb.type s) pageno) ((state-pagedb.type t) pageno))
                         (bveq ((state-pagedb.addrspace s) pageno) ((state-pagedb.addrspace t) pageno)))))
         ; pages
         (forall (list pageno index)
                 (=> (&& (page-valid? pageno) (page-index-valid? index))
                     (bveq ((state-pages s) pageno index) ((state-pages t) pageno index))))
         ; insecure pages
         (forall (list pageno index)
                 (=> (&& (insecure-page-valid? pageno) (page-index-valid? index))
                     (bveq ((state-insecure-pages s) pageno index) ((state-insecure-pages t) pageno index))))))
   (define (hash-proc s hash-recur) 1)
   (define (hash2-proc s hash2-recur) 2)]
  ; pretty-print function
  #:methods gen:custom-write
  [(define (write-proc s port mode)
     (define-symbolic %pageno %index (bitvector 64))
     (fprintf port "(state")
     ; (fprintf port "\n  regs . ~a" (state-regs s))
     (fprintf port "\n  pagedb.type . ~a~a~a" (list %pageno) "~>" ((state-pagedb.type s) %pageno))
     (fprintf port "\n  pagedb.addrspace . ~a~a~a" (list %pageno) "~>" ((state-pagedb.addrspace s) %pageno))
     (fprintf port "\n  pages. ~a~a~a" (list %pageno %index) "~>" ((state-pages s) %pageno %index))
     (fprintf port ")"))])


(define (make-havoc-regs)
  (define-symbolic*
    ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
    satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie
    (bitvector 64))
  (regs ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
    satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie))


(define (make-havoc-state)
  (define-symbolic* symbolic-pagedb.type
                    symbolic-pagedb.addrspace
                    (~> (bitvector 64) (bitvector 64)))
  (define-symbolic* symbolic-pages symbolic-insecure-pages
                    (~> (bitvector 64) (bitvector 64) (bitvector 64)))
  (define-symbolic* enclave-mode boolean?)
  (define host-state (make-havoc-regs))
  (define-symbolic* current-dispatcher current-addrspace (bitvector 64))
  (define page-refcnt (make-havoc-refcnt))
  (define-symbolic* pgtable-pn pgtable-perm (~> (bitvector 64) (bitvector 64) (bitvector 64)))
  (define-symbolic* pgtable-present pgtable-secure (~> (bitvector 64) (bitvector 64) boolean?))
  (state (make-havoc-regs)
         symbolic-pagedb.type
         symbolic-pagedb.addrspace
         symbolic-pages
         symbolic-insecure-pages
         enclave-mode
         host-state
         current-dispatcher
         current-addrspace
         page-refcnt
         pgtable-pn
         pgtable-present
         pgtable-perm
         pgtable-secure))

(define-syntax-rule (make-state-updater name getter setter)
  (define (name state indices value)
    (setter state (update (getter state) indices value))))

(make-state-updater update-state-pagedb.type! state-pagedb.type set-state-pagedb.type!)
(make-state-updater update-state-pagedb.addrspace! state-pagedb.addrspace set-state-pagedb.addrspace!)
(make-state-updater update-state-pages! state-pages set-state-pages!)
(make-state-updater update-state-insecure-pages! state-insecure-pages set-state-insecure-pages!)
(make-state-updater update-state-pgtable-present! state-pgtable-present set-state-pgtable-present!)
(make-state-updater update-state-pgtable-pn! state-pgtable-pn set-state-pgtable-pn!)
(make-state-updater update-state-pgtable-perm! state-pgtable-perm set-state-pgtable-perm!)
(make-state-updater update-state-pgtable-secure! state-pgtable-secure set-state-pgtable-secure!)


(define (state-addrspace.l1pt s pageno)
  ((state-pages s) pageno (bvpointer komodo:KOM_ADDRSPACE_L1PT_PAGE)))

(define (update-state-addrspace.l1pt! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_ADDRSPACE_L1PT_PAGE)) value))

(define (state-addrspace.refcount s pageno)
  ((state-pages s) pageno (bvpointer komodo:KOM_ADDRSPACE_REFCOUNT)))

(define (update-state-addrspace.refcount! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_ADDRSPACE_REFCOUNT)) value))

(define (add1-state-addrspace.refcount! s pageno)
  (update-state-addrspace.refcount! s pageno (bvadd1 (state-addrspace.refcount s pageno))))

(define (sub1-state-addrspace.refcount! s pageno)
  (update-state-addrspace.refcount! s pageno (bvsub1 (state-addrspace.refcount s pageno))))

(define (update-state-addrspace.state! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_ADDRSPACE_STATE)) value))

(define (state-addrspace.state s pageno)
  ((state-pages s) pageno (bvpointer komodo:KOM_ADDRSPACE_STATE)))

(define (addrspace-state? s pageno state)
  (bveq (state-addrspace.state s pageno) (bv state 64)))

(define (state-dispatcher.entered s pageno)
  ((state-pages s) pageno (bvpointer komodo:KOM_DISPATCHER_ENTERED)))

(define (update-state-dispatcher.entered! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_ENTERED)) value))

(define (state-dispatcher.regs.ra s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_RA))))
(define (state-dispatcher.regs.sp s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_SP))))
(define (state-dispatcher.regs.gp s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_GP))))
(define (state-dispatcher.regs.tp s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_TP))))

(define (state-dispatcher.regs.a0 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A0))))
(define (state-dispatcher.regs.a1 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A1))))
(define (state-dispatcher.regs.a2 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A2))))
(define (state-dispatcher.regs.a3 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A3))))
(define (state-dispatcher.regs.a4 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A4))))
(define (state-dispatcher.regs.a5 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A5))))
(define (state-dispatcher.regs.a6 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A6))))
(define (state-dispatcher.regs.a7 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A7))))

(define (state-dispatcher.regs.s0 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S0))))
(define (state-dispatcher.regs.s1 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S1))))
(define (state-dispatcher.regs.s2 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S2))))
(define (state-dispatcher.regs.s3 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S3))))
(define (state-dispatcher.regs.s4 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S4))))
(define (state-dispatcher.regs.s5 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S5))))
(define (state-dispatcher.regs.s6 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S6))))
(define (state-dispatcher.regs.s7 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S7))))
(define (state-dispatcher.regs.s8 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S8))))
(define (state-dispatcher.regs.s9 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S9))))
(define (state-dispatcher.regs.s10 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S10))))
(define (state-dispatcher.regs.s11 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S11))))

(define (state-dispatcher.regs.t0 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T0))))
(define (state-dispatcher.regs.t1 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T1))))
(define (state-dispatcher.regs.t2 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T2))))
(define (state-dispatcher.regs.t3 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T3))))
(define (state-dispatcher.regs.t4 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T4))))
(define (state-dispatcher.regs.t5 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T5))))
(define (state-dispatcher.regs.t6 s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T6))))


(define (state-dispatcher.mepc s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_MEPC))))
(define (state-dispatcher.satp s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SATP))))
(define (state-dispatcher.stvec s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_STVEC))))
(define (state-dispatcher.scounteren s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SCOUNTEREN))))
(define (state-dispatcher.stval s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_STVAL))))
(define (state-dispatcher.sip s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SIP))))
(define (state-dispatcher.scause s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SCAUSE))))
(define (state-dispatcher.sepc s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SEPC))))
(define (state-dispatcher.sstatus s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SSTATUS))))
(define (state-dispatcher.sscratch s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SSCRATCH))))
(define (state-dispatcher.sie s pageno)
  (apply (state-pages s) (list pageno (bvpointer komodo:KOM_DISPATCHER_SIE))))


(define (update-state-dispatcher.regs.ra! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_RA)) value))
(define (update-state-dispatcher.regs.sp! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_SP)) value))
(define (update-state-dispatcher.regs.gp! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_GP)) value))
(define (update-state-dispatcher.regs.tp! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_TP)) value))

(define (update-state-dispatcher.regs.a0! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A0)) value))
(define (update-state-dispatcher.regs.a1! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A1)) value))
(define (update-state-dispatcher.regs.a2! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A2)) value))
(define (update-state-dispatcher.regs.a3! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A3)) value))
(define (update-state-dispatcher.regs.a4! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A4)) value))
(define (update-state-dispatcher.regs.a5! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A5)) value))
(define (update-state-dispatcher.regs.a6! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A6)) value))
(define (update-state-dispatcher.regs.a7! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_A7)) value))

(define (update-state-dispatcher.regs.s0! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S0)) value))
(define (update-state-dispatcher.regs.s1! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S1)) value))
(define (update-state-dispatcher.regs.s2! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S2)) value))
(define (update-state-dispatcher.regs.s3! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S3)) value))
(define (update-state-dispatcher.regs.s4! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S4)) value))
(define (update-state-dispatcher.regs.s5! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S5)) value))
(define (update-state-dispatcher.regs.s6! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S6)) value))
(define (update-state-dispatcher.regs.s7! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S7)) value))
(define (update-state-dispatcher.regs.s8! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S8)) value))
(define (update-state-dispatcher.regs.s9! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S9)) value))
(define (update-state-dispatcher.regs.s10! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S10)) value))
(define (update-state-dispatcher.regs.s11! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_S11)) value))

(define (update-state-dispatcher.regs.t0! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T0)) value))
(define (update-state-dispatcher.regs.t1! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T1)) value))
(define (update-state-dispatcher.regs.t2! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T2)) value))
(define (update-state-dispatcher.regs.t3! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T3)) value))
(define (update-state-dispatcher.regs.t4! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T4)) value))
(define (update-state-dispatcher.regs.t5! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T5)) value))
(define (update-state-dispatcher.regs.t6! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_REGS_T6)) value))


(define (update-state-dispatcher.mepc! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_MEPC)) value))
(define (update-state-dispatcher.satp! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SATP)) value))
(define (update-state-dispatcher.stvec! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_STVEC)) value))
(define (update-state-dispatcher.scounteren! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SCOUNTEREN)) value))
(define (update-state-dispatcher.stval! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_STVAL)) value))
(define (update-state-dispatcher.sip! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SIP)) value))
(define (update-state-dispatcher.scause! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SCAUSE)) value))
(define (update-state-dispatcher.sepc! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SEPC)) value))
(define (update-state-dispatcher.sstatus! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SSTATUS)) value))
(define (update-state-dispatcher.sscratch! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SSCRATCH)) value))
(define (update-state-dispatcher.sie! s pageno value)
  (update-state-pages! s (list pageno (bvpointer komodo:KOM_DISPATCHER_SIE)) value))


(define (page-valid? pageno)
  (bvult pageno (bv komodo:KOM_SECURE_NPAGES 64)))

(define (page-typed? s pageno type)
  (&& (page-valid? pageno)
      (bveq ((state-pagedb.type s) pageno) (bv type 64))))

(define (page-free? s pageno)
  (page-typed? s pageno komodo:KOM_PAGE_FREE))

(define (page-index-valid? index)
  (bvult index (bv 512 64)))

(define pte-index-valid? page-index-valid?)

(define (insecure-page-valid? pageno)
  (bvult pageno (bv komodo:KOM_INSECURE_NPAGES 64)))

(define (enclave-prot mapping)
  (bvor (bvand mapping (bv komodo:_PAGE_RWX 64))
        (bv komodo:_PAGE_ENCLAVE 64)))
