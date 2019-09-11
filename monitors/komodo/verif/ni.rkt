#lang rosette/safe

(require
  serval/lib/unittest
  serval/lib/core
  "state.rkt"
  "spec.rkt"
  "invariants.rkt"
  (only-in racket/base exn:fail? struct-copy string-append parameterize)
  (prefix-in komodo: "generated/monitors/komodo/verif/asm-offsets.rkt")
)

(provide (all-defined-out))

(define (stopped-addrspace s obs)
  (bveq (state-addrspace.state s obs)
        (bv komodo:KOM_ADDRSPACE_STOPPED 64)))

; (define (loweq-entry pageno index s1 s2)
;   (||
;     (&& (page-typed? s1 pageno komodo:KOM_PAGE_DATA)
;         (page-typed? s2 pageno komodo:KOM_PAGE_DATA))
;     (&& (page-typed? s1 pageno komodo:KOM_PAGE_L1PTABLE)
;         (page-typed? s2 pageno komodo:KOM_PAGE_L1PTABLE)
;         (bveq ((state-pages s1) pageno index) ((state-pages s2) pageno index)))
;     (&& (page-typed? s1 pageno komodo:KOM_PAGE_L2PTABLE)
;         (page-typed? s2 pageno komodo:KOM_PAGE_L2PTABLE)
;         (bveq ((state-pages s1) pageno index) ((state-pages s2) pageno index)))
;     (&& (page-typed? s1 pageno komodo:KOM_PAGE_L3PTABLE)
;         (page-typed? s2 pageno komodo:KOM_PAGE_L3PTABLE)
;         (bveq ((state-pages s1) pageno index) ((state-pages s2) pageno index)))
;     (&& (page-typed? s1 pageno komodo:KOM_PAGE_ADDRSPACE)
;         (page-typed? s2 pageno komodo:KOM_PAGE_ADDRSPACE)
;         (bveq (state-addrspace.refcount s1 pageno) (state-addrspace.refcount s2 pageno))
;         (bveq (state-addrspace.state s1 pageno) (state-addrspace.state s2 pageno)))
;     (&& (page-typed? s1 pageno komodo:KOM_PAGE_DISPATCHER)
;         (page-typed? s2 pageno komodo:KOM_PAGE_DISPATCHER)
;         (bveq (state-dispatcher.entered s1 pageno) (state-dispatcher.entered s2 pageno)))
;   ))

(define (loweq-pdb s1 s2 obs)
  (define-symbolic pageno index (bitvector 64))
  (&&
    (page-typed? s1 obs komodo:KOM_PAGE_ADDRSPACE)
    (page-typed? s2 obs komodo:KOM_PAGE_ADDRSPACE)
    (! (stopped-addrspace s1 obs))
    (! (stopped-addrspace s2 obs))
    (equal? (state-enclave-mode s1) (state-enclave-mode s2))
    (forall (list pageno)
      (=> (page-valid? pageno)
        (<=>
          (page-free? s1 pageno)
          (page-free? s2 pageno))))
    (forall (list pageno)
      (=> (page-valid? pageno)
        (bveq ((state-pagedb.type s1) pageno)
              ((state-pagedb.type s2) pageno))))
    (forall (list pageno)
      (=> (page-valid? pageno)
        (bveq ((state-pagedb.addrspace s1) pageno)
              ((state-pagedb.addrspace s2) pageno))))
    (forall (list pageno index)
      (=> (&& (page-valid? pageno)
              (page-index-valid? index)
              (|| (bveq obs ((state-pagedb.addrspace s1) pageno))
                  (page-typed? s1 pageno komodo:KOM_PAGE_ADDRSPACE)
                  (page-typed? s1 pageno komodo:KOM_PAGE_DISPATCHER)
                  (page-typed? s1 pageno komodo:KOM_PAGE_L1PTABLE)
                  (page-typed? s1 pageno komodo:KOM_PAGE_L2PTABLE)
                  (page-typed? s1 pageno komodo:KOM_PAGE_L3PTABLE)))
        (bveq ((state-pages s1) pageno index)
              ((state-pages s2) pageno index))))
    ; (forall (list pageno index)
    ;   (=> (&& (page-valid? pageno)
    ;           (page-index-valid? index))
    ;     (loweq-entry pageno index s1 s2)))
  ))

(define (loweq-pdb-symmetry)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define-symbolic* obs (bitvector 64))
  (check-unsat? (verify (assert (=> (loweq-pdb s t obs) (loweq-pdb t s obs))))))

(define (loweq-pdb-reflexivity)
  (define s (make-havoc-state))
  (define-symbolic* obs (bitvector 64))
  (check-sat? (solve (assert (loweq-pdb s s obs)))))

(define (verify-integrity spec [args null])
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define old-s (struct-copy state s))
  (define old-t (struct-copy state t))
  (define-symbolic* obs (bitvector 64))

  (define pre (&& (apply && (flatten (spec-lemmas old-s)))
                  (apply && (flatten (spec-lemmas old-t)))
                  (loweq-pdb old-s old-t obs)))

  (apply spec s args)
  (apply spec t args)

  (define post (loweq-pdb s t obs))

  (check-unsat? (verify (assert (=> pre post))))
)

; (define komodo-ni-tests
;   (test-suite+ "komodo NI tests"

;     ; (test-case+ "loweq-pdb symmetry"
;     ;   (loweq-pdb-symmetry))

;     ; (test-case+ "loweq-pdb reflexive sat"
;     ;   (loweq-pdb-reflexivity))

;     ; (test-case+ "kom_smc_query integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_query)))
;     ; (test-case+ "kom_smc_get_phys_pages integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_get_phys_pages)))
;     ; (test-case+ "kom_smc_init_addrspace integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_init_addrspace) (list (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_init_dispatcher integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_init_dispatcher) (list (make-bv64) (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_init_l2ptable integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_init_l2ptable) (list (make-bv64) (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_init_l3ptable integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_init_l3ptable) (list (make-bv64) (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_map_secure integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_map_secure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_map_insecure integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_map_insecure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_copy_data integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_copy_data) (list (make-bv64) (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_remove integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_remove) (list (make-bv64))))
;     ; (test-case+ "kom_smc_finalise integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_finalise) (list (make-bv64))))
;     ; ; (test-case+ "kom_smc_stop integrity"
;     ; ;   (verify-integrity (make-smc-spec spec-kom_smc_stop) KOM_SMC_STOP (list (make-bv64))))
;     ; (test-case+ "kom_smc_enter integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_enter) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
;     ; (test-case+ "kom_smc_resume integrity"
;     ;   (verify-integrity (make-smc-spec spec-kom_smc_resume) (list (make-bv64))))
;     ; (test-case+ "kom_svc_exit integrity"
;     ;   (verify-integrity spec-kom_svc_exit (list (make-bv64))))


;   ))

; (module+ test
;   (run-tests komodo-ni-tests))