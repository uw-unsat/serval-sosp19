#lang rosette/safe

(require
  serval/lib/unittest
  serval/lib/core
  "state.rkt"
  "spec.rkt"
  (only-in racket/base exn:fail? struct-copy string-append parameterize)
  (prefix-in keystone: "generated/monitors/keystone/verif/asm-offsets.rkt")
)

(provide (all-defined-out))

(define (enclave-state-equiv s t)
  (define-symbolic eid (bitvector 64))
  (forall (list eid)
    (=> (eid-valid? eid)
      (equal? ((state-enclave.status s) eid)
              ((state-enclave.status t) eid)))))

(define (check-state-preserved spec [args null])
  (define s (make-havoc-state))
  (define old-s (struct-copy state s))

  (check-asserts-only (apply spec s args))

  (define pre (&& (state-enclave-mode old-s)
                  (state-enclave-mode s)))

  (define post (check-asserts (enclave-state-equiv old-s s)))

  (check-equal? (asserts) null)
  (check-unsat? (verify (assert (=> pre post)))))


(define keystone-ni-tests
  (test-suite+ "keystone NI tests"

    (test-case+ "sys_create_enclave property"
      (check-state-preserved spec-sys_create_enclave
        (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64))))

    (test-case+ "sys_destroy_enclave property"
      (check-state-preserved spec-sys_destroy_enclave
        (list (make-bv64))))
    (test-case+ "sys_run_enclave property"
      (check-state-preserved spec-sys_run_enclave
        (list (make-bv64))))
    (test-case+ "sys_exit_enclave property"
      (check-state-preserved spec-sys_exit_enclave
        null))
    (test-case+ "sys_resume_enclave property"
      (check-state-preserved spec-sys_resume_enclave
        (list (make-bv64))))


  ))

(module+ test
  (time (run-tests keystone-ni-tests)))
