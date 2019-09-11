#lang rosette

(require
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  "generated/racket/test/pyudiv.py.rkt"
  (prefix-in core: serval/lib/core)
  (prefix-in python: serval/python)
  serval/lib/unittest)

(define (spec-udiv x y)
  (if (core:bvzero? y) (bv 0 32) (bvudiv x y)))

(define (check-pyudiv)
  (define-symbolic x y (bitvector 32))
  (define interp (python:make-interpreter pyudiv (list x y)))
  (define-values (result asserted)
    (with-asserts (python:interpret-program interp)))
  (check-equal? asserted null)
  (check-unsat? (verify (assert (equal? result (spec-udiv x y))))))

(define pyudiv-tests
  (test-suite+
   "Tests for pyudiv"
    (test-case+ "pyudiv" (check-pyudiv))
  ))

(module+ test
  (time (run-tests pyudiv-tests)))

