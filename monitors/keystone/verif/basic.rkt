#lang rosette

(require (except-in rackunit fail)
         rackunit/text-ui
         rosette/lib/roseunit
         serval/lib/unittest
         (prefix-in core: serval/lib/core)
         (prefix-in riscv: serval/riscv/objdump)
         (prefix-in keystone: "symbols.rkt")
         (prefix-in keystone: "generated/monitors/keystone.asm.rkt"))


(define (check-keystone)
  ; Start a CPU in fresh, just-after-reset state
  (define cpu0 (riscv:init-cpu keystone:symbols keystone:globals))

  ; hartid = 1
  (riscv:gpr-set! cpu0 'a0 (bv 1 (riscv:XLEN)))

  ; Interpret the monitor until the first mret
  (riscv:interpret-objdump-program cpu0 keystone:instructions)

  ; Set new PC to be mtvec
  (riscv:set-cpu-pc! cpu0 (riscv:csr-ref cpu0 'mtvec))

  ; Trash every GPR
  (for ([i (range 32)])
    (riscv:gpr-havoc! cpu0 i))

  (riscv:csr-set! cpu0 'mcause (bv 9 (riscv:XLEN))) ; EXC_ECALL_S
  (riscv:gpr-set! cpu0 'a7 (bv 13 (riscv:XLEN))) ; Resume enclave

  ; Run again (from machine_trap_vector this time)
  (define as (with-asserts-only (riscv:interpret-objdump-program cpu0 keystone:instructions)))

  (check-equal? (asserts) null)
  (displayln "Checking asserts")

  (check-unsat? (verify (assert (apply && as))))

  (define return-code (riscv:gpr-ref cpu0 'a0))

  (check-unsat? (verify (assert (|| (bveq return-code (bv 0 64))
                                   (bveq return-code (bvneg (bv 22 64)))))))

  (void))

(define (check-keystone-symbols)
  (check-equal? (core:find-overlapping-symbol keystone:symbols) #f "Symbol overlap check failed"))

(define keystone-tests
  (test-suite+ "Encmon verification tests"
   ;(test-case+ "Check keystone" (check-keystone))
   (test-case+ "Encmon symbol check" (check-keystone-symbols))
  ))

(module+ test
  (time (run-tests keystone-tests)))
