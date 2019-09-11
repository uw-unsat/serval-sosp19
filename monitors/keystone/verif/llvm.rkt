#lang rosette

(require (except-in rackunit fail)
         rackunit/text-ui
         rosette/lib/roseunit
         serval/llvm
         serval/lib/core
         serval/lib/unittest
         serval/spec/refinement
         "spec.rkt"
         "impl.rkt"
         "state.rkt"
         (prefix-in keystone: "symbols.rkt")
         (prefix-in keystone: "generated/monitors/keystone/verif/asm-offsets.rkt"))

(require "spec.rkt")

(require "generated/monitors/keystone.ll.rkt")

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
  (define machine (make-machine keystone:symbols keystone:globals))
  (verify-refinement
    #:implstate machine
    #:impl (make-machine-func impl-func)
    #:specstate (make-havoc-state)
    #:spec spec-func
    #:abs abs-function
    #:ri (compose1 mregions-invariants machine-mregions)
    args))

(define keystone-llvm-tests
  (test-suite+ "keystone LLVM tests"
    (test-case+ "sys_create_enclave LLVM"
      (verify-llvm-refinement spec-sys_create_enclave @sys_create_enclave (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "sys_destroy_enclave LLVM"
      (verify-llvm-refinement spec-sys_destroy_enclave @sys_destroy_enclave (list (make-bv64))))
    (test-case+ "sys_run_enclave LLVM"
      (verify-llvm-refinement spec-sys_run_enclave @sys_run_enclave (list (make-bv64))))
    (test-case+ "sys_exit_enclave LLVM"
      (verify-llvm-refinement spec-sys_exit_enclave @sys_exit_enclave null))
    (test-case+ "sys_resume_enclave LLVM"
      (verify-llvm-refinement spec-sys_resume_enclave @sys_resume_enclave (list (make-bv64))))
))

(module+ test
  (time (run-tests keystone-llvm-tests)))
