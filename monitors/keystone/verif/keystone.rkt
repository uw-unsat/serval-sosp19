#lang rosette

(require (except-in rackunit fail)
         rackunit/text-ui
         rosette/lib/roseunit
         serval/llvm
         serval/lib/core
         serval/lib/unittest
         (prefix-in keystone: "generated/monitors/keystone.map.rkt")
         (prefix-in keystone: "generated/monitors/keystone.globals.rkt"))

(require "generated/monitors/keystone.ll.rkt")

(define (make-arg type)
  (define-symbolic* symbolic-arg type)
  symbolic-arg)

(define (make-bv32)
  (make-arg (bitvector 32)))

(define (rep-invariant mregions)
  #t)

(define (verify-llvm-assert expr ri)
  (define sol (verify (assert (=> ri expr))))
  (when (sat? sol)
    (define-values (loc msg) (assertion-info sol))
    (displayln (cons loc msg))))

(define (check-llvm-ub func [args null])
  (define machine (make-machine keystone:symbols keystone:globals))
  (define s (machine-mregions machine))
  (parameterize ([current-machine machine])
    (define ri (rep-invariant s))
    (define asserted
      (with-asserts-only (begin (assert ri) (apply func args))))
    (for-each (lambda (e) (verify-llvm-assert e ri)) asserted)))

(define keystone-tests
  (test-suite+ "keystone tests"
    (test-case+ "destroy_enclave"
      (check-llvm-ub @destroy_enclave (list (make-bv32))))
))

(module+ test
  (time (run-tests keystone-tests)))
