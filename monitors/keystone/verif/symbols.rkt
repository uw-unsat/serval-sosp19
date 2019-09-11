#lang racket

(require
  (prefix-in @ "generated/monitors/keystone.map.rkt")
  "generated/monitors/keystone.globals.rkt"
  "generated/monitors/keystone/verif/asm-offsets.rkt")

(provide symbols globals)

(define (update-symbol-size lst s n)
  (list-update lst
               (index-where lst (lambda (x) (equal? (last x) s)))
               (lambda (x) (list-set x 1 (+ (first x) n)))))

; patch the size of _payload_start to be MAX_PAYLOAD_SIZE
(define symbols (update-symbol-size @symbols '_payload_start MAX_PAYLOAD_SIZE))
