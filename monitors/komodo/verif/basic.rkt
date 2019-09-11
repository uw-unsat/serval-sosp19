#lang rosette/safe

(require
  serval/lib/core
  serval/lib/unittest
  (prefix-in komodo: "symbols.rkt")
)

(define (check-komodo-symbols)
  (check-equal? (find-overlapping-symbol komodo:symbols) #f "Symbol overlap check failed"))

(define komodo-basic-tests
  (test-suite+ "komodo basic tests"
    (test-case+ "komodo symbol check" (check-komodo-symbols))
))

(module+ test
  (time (run-tests komodo-basic-tests)))

