#lang rosette/safe

(require
  serval/lib/core
  serval/lib/unittest
  (prefix-in certikos: "generated/monitors/certikos.map.rkt")
)

(define (check-certikos-symbols)
  (check-equal? (find-overlapping-symbol certikos:symbols) #f "Symbol overlap check failed"))

(define certikos-basic-tests
  (test-suite+ "certikos basic tests"
    (test-case+ "Isomon symbol check" (check-certikos-symbols))
))

(module+ test
  (time (run-tests certikos-basic-tests)))
