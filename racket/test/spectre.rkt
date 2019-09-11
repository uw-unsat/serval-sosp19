#lang rosette

(require (except-in rackunit fail)
         rackunit/text-ui
         rosette/lib/roseunit
         serval/lib/core
         serval/llvm
         serval/lib/unittest)

(require "generated/racket/test/spectre.globals.rkt"
         "generated/racket/test/spectre.map.rkt")

(require "generated/racket/test/spectre.ll.rkt")

(define (check-spectre func spectre pred)
  (parameterize ([current-machine (make-machine symbols globals)]
                 [target-spectre spectre])
    (define-symbolic i (bitvector 64))
    (define asserted
      (with-spectre-asserts-only (func i)))
    (check-sol pred (verify (assert (apply && asserted))))))

(define spectre-tests
  (test-suite+
   "Tests for spectre.c"

   (test-case+ "check-read (spectre off)"
     (check-spectre @test_read #f unsat?))
   (test-case+ "check-read (spectre on)"
     (check-spectre @test_read #t sat?))
   (test-case+ "check-read-nospec (spectre off)"
     (check-spectre @test_read_nospec #f unsat?))
   (test-case+ "check-read-nospec (spectre on)"
     (check-spectre @test_read_nospec #t unsat?))))

(module+ test
  (time (run-tests spectre-tests)))
