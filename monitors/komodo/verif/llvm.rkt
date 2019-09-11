#lang rosette/safe

(require
  serval/llvm
  serval/lib/core
  serval/lib/unittest
  serval/spec/refinement
  "spec.rkt"
  "impl.rkt"
  "state.rkt"
  (only-in racket/base parameterize struct-copy)
  (prefix-in komodo: "symbols.rkt")
  (prefix-in komodo: "generated/monitors/komodo/verif/asm-offsets.rkt")
)

(require "spec.rkt")

(require "generated/monitors/komodo.ll.rkt")

(define (make-machine-func func)
  (lambda (machine . args)
    (parameterize ([current-machine machine])
      (define result (apply func args))
      (set-machine-retval! machine result))))

(define (abs-function machine)
  (define s (mregions-abstract (machine-mregions machine)))
  (set-state-regs! s (struct-copy regs (state-regs s) [a0 (machine-retval machine)]))
  s)

(define (verify-llvm-refinement spec-func impl-func [args null])
  (define machine (make-machine komodo:symbols komodo:globals))
  (verify-refinement
    #:implstate machine
    #:impl (make-machine-func impl-func)
    #:specstate (make-havoc-state)
    #:spec spec-func
    #:abs abs-function
    #:ri (compose1 mregions-invariants machine-mregions)
    args))

(define (llvm-kom_smc_enter s disp_page a0 a1 a2)
  (define addrspace_page ((state-pagedb.addrspace s) disp_page))
  (cond
    [(! (page-typed? s disp_page komodo:KOM_PAGE_DISPATCHER))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_FINAL))
      (set-return! s komodo:KOM_ERR_NOT_FINAL)]
    [(! (bvzero? (state-dispatcher.entered s disp_page)))
      (set-return! s komodo:KOM_ERR_ALREADY_ENTERED)]
    [else
      (set-return! s komodo:KOM_ERR_SUCCESS)
      (update-state-dispatcher.regs.a0! s disp_page a0)
      (update-state-dispatcher.regs.a1! s disp_page a1)
      (update-state-dispatcher.regs.a2! s disp_page a2)]))


(define (llvm-kom_smc_resume s disp_page)
  (define addrspace_page ((state-pagedb.addrspace s) disp_page))
  (cond
    [(! (page-typed? s disp_page komodo:KOM_PAGE_DISPATCHER))
      (set-return! s komodo:KOM_ERR_INVALID_PAGENO)]
    [(! (addrspace-state? s addrspace_page komodo:KOM_ADDRSPACE_FINAL))
      (set-return! s komodo:KOM_ERR_NOT_FINAL)]
    [(bvzero? (state-dispatcher.entered s disp_page))
      (set-return! s komodo:KOM_ERR_NOT_ENTERED)]
    [else
      (set-return! s komodo:KOM_ERR_SUCCESS)]))


(define komodo-llvm-tests
  (test-suite+ "komodo LLVM tests"
    (test-case+ "kom_smc_query LLVM"
      (verify-llvm-refinement spec-kom_smc_query @kom_smc_query))
    (test-case+ "kom_smc_get_phys_pages LLVM"
      (verify-llvm-refinement spec-kom_smc_get_phys_pages @kom_smc_get_phys_pages))
    (test-case+ "kom_smc_init_addrspace LLVM"
      (verify-llvm-refinement spec-kom_smc_init_addrspace @kom_smc_init_addrspace (list (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_init_dispatcher LLVM"
      (verify-llvm-refinement spec-kom_smc_init_dispatcher @kom_smc_init_dispatcher (list (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_init_l2ptable LLVM"
      (verify-llvm-refinement spec-kom_smc_init_l2ptable @kom_smc_init_l2ptable (list (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_init_l3ptable LLVM"
      (verify-llvm-refinement spec-kom_smc_init_l3ptable @kom_smc_init_l3ptable (list (make-bv64) (make-bv64) (make-bv64))))
    ; (test-case+ "kom_smc_map_secure LLVM"
    ;   (verify-llvm-refinement spec-kom_smc_map_secure @kom_smc_map_secure (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_map_insecure LLVM"
      (verify-llvm-refinement spec-kom_smc_map_insecure @kom_smc_map_insecure (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_remove LLVM"
      (verify-llvm-refinement spec-kom_smc_remove @kom_smc_remove (list (make-bv64))))
    (test-case+ "kom_smc_finalise LLVM"
      (verify-llvm-refinement spec-kom_smc_finalise @kom_smc_finalise (list (make-bv64))))
    (test-case+ "kom_smc_stop LLVM"
      (verify-llvm-refinement spec-kom_smc_stop @kom_smc_stop (list (make-bv64))))
    (test-case+ "kom_smc_enter LLVM"
      (verify-llvm-refinement llvm-kom_smc_enter @kom_smc_enter (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_resume LLVM"
      (verify-llvm-refinement llvm-kom_smc_resume @kom_smc_resume (list (make-bv64))))
))

(module+ test
  (time (run-tests komodo-llvm-tests)))
