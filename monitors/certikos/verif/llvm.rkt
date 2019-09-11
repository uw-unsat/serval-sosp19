#lang rosette/safe

(require
  serval/llvm
  serval/lib/core
  serval/lib/unittest
  serval/spec/refinement
  "spec.rkt"
  "impl.rkt"
  "state.rkt"
  (prefix-in certikos: "generated/monitors/certikos.map.rkt")
  (prefix-in certikos: "generated/monitors/certikos.globals.rkt")
  (prefix-in certikos: "generated/monitors/certikos/verif/asm-offsets.rkt")
  (only-in racket/base parameterize struct-copy)
)

(require "generated/monitors/certikos.ll.rkt")


(provide (all-defined-out))

(define (make-machine-func func)
  (lambda (machine . args)
    (parameterize ([current-machine machine] [target-spectre #t])
      (define result (apply func args))
      (set-machine-retval! machine result))))

(define (abs-function machine)
  (define st (mregions-abstract (machine-mregions machine)))
  (set-state-regs! st (struct-copy regs (state-regs st) [a0 (machine-retval machine)]))
  st)

(define (verify-llvm-refinement spec-func impl-func [args null])
  (define machine (make-machine certikos:symbols certikos:globals))
  (verify-refinement
    #:implstate machine
    #:impl (make-machine-func impl-func)
    #:specstate (make-havoc-state)
    #:spec spec-func
    #:abs abs-function
    #:ri (compose1 mregions-invariants machine-mregions)
    args))

(define certikos-llvm-tests
  (test-suite+ "certikos LLVM tests"
    (test-case+ "sys_getpid LLVM"
      (verify-llvm-refinement spec-sys_getpid @sys_getpid))
    (test-case+ "sys_get_quota LLVM"
      (verify-llvm-refinement spec-sys_get_quota @sys_get_quota))
    (test-case+ "do_yield LLVM"
      (verify-llvm-refinement spec-do_yield @do_yield))
    (test-case+ "sys_spawn LLVM"
      (verify-llvm-refinement spec-sys_spawn @sys_spawn (list (make-bv64) (make-bv64) (make-bv64))))
))

(module+ test
  (time (run-tests certikos-llvm-tests)))
