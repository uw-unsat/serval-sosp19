#lang rosette

(require (except-in rackunit fail)
         rackunit/text-ui
         rosette/lib/roseunit
         (prefix-in core: serval/lib/core)
         (prefix-in riscv: serval/riscv/objdump)
         (prefix-in testmon: "generated/monitors/testmon.map.rkt")
         (prefix-in testmon: "generated/monitors/testmon.asm.rkt"))

(core:target-endian 'little)
(core:target-pointer-bitwidth 64)

(define (check-testmon)
  (define noop_test (list-ref (core:find-symbol-by-name testmon:symbols 'noop_test) 0))

  ; Find the special mret symbol that points to a function that just calls
  ; mret in a loop. We'll set ra (return address) to this function to get control
  ; back after running the test.
  (define mret_start (list-ref (core:find-symbol-by-name testmon:symbols 'mret) 0))

  (define cpu (riscv:init-cpu testmon:symbols null))

  (riscv:gpr-set! cpu 'ra (bv mret_start 64))
  (riscv:set-cpu-pc! cpu (bv noop_test 64))
  (riscv:interpret-objdump-program cpu testmon:instructions)
  (check-equal? (asserts) null)

  (void))

(define testmon-tests
  (test-suite+ "testmon verification tests"
   (test-case "Check testmon" (check-testmon))
  ))

(module+ test
  (time (run-tests testmon-tests)))
