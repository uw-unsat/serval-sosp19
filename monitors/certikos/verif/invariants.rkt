#lang rosette

(require "spec.rkt"
  serval/lib/core
  serval/lib/unittest
  "state.rkt"
)

(provide (all-defined-out))

(define (spec-invariants st)
  (define current-pid (state-current-pid st))
  (define (pid->owner pid)
    ((state-proc.owner st) pid))
  (define (pid->lower pid)
    ((state-proc.lower st) pid))
  (define (pid->upper pid)
    ((state-proc.upper st) pid))
  (define (pid-run? pid)
    (proc.state-run? ((state-proc.state st) pid)))
  (define (page->owner page)
    ((state-page.owner st) page))
  (define-symbolic pid page q (bitvector 64))
  (&&
    (pid-valid? current-pid)
    (pid-run? current-pid)
    (forall (var pid)
      (=> (&& (pid-valid? pid) (not (pid-run? pid)))
        (&& (bveq (pid->upper pid) (bv 0 64))
            (bveq (pid->lower pid) (bv 0 64)))))
    (forall (var pid)
      (=> (&& (pid-valid? pid) (pid-run? pid))
        (&& (pid-valid? ((state-proc.next st) pid))
            (pid-run? ((state-proc.next st) pid)))))

    (forall (var page pid)
      (=> (&& (pid-valid? pid) (pindex-valid? page) (bvuge page (pid->lower pid)) (bvult page (pid->upper pid)))
        (bveq (page->owner page) pid)))

    (forall (var pid)
      (=> (pid-valid? pid)
          (pid-valid? ((state-proc.owner st) pid))))
    (forall (var pid)
      (=> (pid-valid? pid)
        (&& (bvule (pid->upper pid) (nr-pages))
            (bvule (pid->lower pid) (pid->upper pid)))))))

(define (verify-invariants spec [args null])
  (define state (make-havoc-state))
  (define pre (spec-invariants state))
  (check-equal? (asserts) null)
  (define spec-asserted (with-asserts-only (apply spec state args)))
  (check-unsat? (verify (assert (apply && spec-asserted))))
  (define-values (post post-asserted) (with-asserts (spec-invariants state)))
  (check-unsat? (verify (assert (apply && post-asserted))))
  (check-unsat? (verify (assert (=> pre post)))))

(define spec-tests
  (test-suite+ "certikos spec tests"
    (test-case+ "write-regs invariants" (verify-invariants spec-write-regs (list (make-havoc-regs))))
    (test-case+ "write invariants" (verify-invariants spec-write (list (make-bv64) (make-bv64) (make-bv8))))
    (test-case+ "yield invariants" (verify-invariants spec-sys_yield))
    (test-case+ "getpid invariants" (verify-invariants spec-sys_getpid))
    (test-case+ "get_quota invariants" (verify-invariants spec-sys_get_quota))
    (test-case+ "spawn invariants" (verify-invariants spec-sys_spawn (list (make-bv64) (make-bv64) (make-bv64))))
))

(module+ test
  (time (run-tests spec-tests)))
