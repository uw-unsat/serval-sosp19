#lang racket

(require
  (prefix-in @ "generated/monitors/komodo.map.rkt")
  "generated/monitors/komodo.globals.rkt"
  "generated/monitors/komodo/verif/asm-offsets.rkt")

(provide symbols globals)

(define (update-symbol-size lst s n)
  (list-update lst
               (index-where lst (lambda (x) (equal? (last x) s)))
               (lambda (x) (list-set x 1 (+ (first x) n)))))

; patch the size of _payload_start to be KOM_INSECURE_RESERVE
(define symbols (update-symbol-size @symbols '_payload_start KOM_INSECURE_RESERVE))
