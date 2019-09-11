#lang rosette/safe

(require rackunit
         serval/lib/core
         serval/lib/unittest
         "state.rkt"
         (only-in racket/base struct-copy)
         (prefix-in keystone: "generated/monitors/keystone/verif/asm-offsets.rkt"))

(provide (all-defined-out))


(define (set-return! s val)
  (set-state-regs! s (struct-copy regs (state-regs s) [a0 (bv val 64)])))


(define (spec-sys_create_enclave s eid entry secure-lower secure-upper shared-lower shared-upper)
  (cond
    [(state-enclave-mode s)
     (set-return! s (- keystone:EINVAL))]
    [(! (eid-valid? eid))
     (set-return! s (- keystone:EINVAL))]
    [(! (equal? ((state-enclave.status s) eid) (bv keystone:ENCLAVE_FREE 64)))
     (set-return! s (- keystone:EINVAL))]
    [(! (region-valid? secure-lower secure-upper))
     (set-return! s (- keystone:EINVAL))]
    [(! (region-valid? shared-lower shared-upper))
     (set-return! s (- keystone:EINVAL))]
    [(! (region-nonoverlap? s secure-lower secure-upper))
     (set-return! s (- keystone:EINVAL))]
    [else
     (update-state-enclave.status! s (list eid) (bv keystone:ENCLAVE_FRESH 64))
     (update-state-enclave.entry! s (list eid) entry)
     (update-state-enclave.secure-lower! s (list eid) secure-lower)
     (update-state-enclave.secure-upper! s (list eid) secure-upper)
     (update-state-enclave.shared-lower! s (list eid) shared-lower)
     (update-state-enclave.shared-upper! s (list eid) shared-upper)
     (set-return! s 0)]))


(define (spec-sys_destroy_enclave s eid)
  (cond
    [(state-enclave-mode s)
     (set-return! s (- keystone:EINVAL))]
    [(! (eid-valid? eid))
     (set-return! s (- keystone:EINVAL))]
    [(&& (! (equal? ((state-enclave.status s) eid) (bv keystone:ENCLAVE_IDLE 64)))
         (! (equal? ((state-enclave.status s) eid) (bv keystone:ENCLAVE_FRESH 64))))
     (set-return! s (- keystone:EINVAL))]
    [else
     (define secure-lower ((state-enclave.secure-lower s) eid))
     (define secure-upper ((state-enclave.secure-upper s) eid))
     (update-state-enclave.status! s (list eid) (bv keystone:ENCLAVE_FREE 64))
     (update-state-enclave.secure-lower! s (list eid) (bv 0 64))
     (update-state-enclave.secure-upper! s (list eid) (bv 0 64))
     (define (inbounds? offset)
       (&& (bvuge offset secure-lower)
           (bvult offset secure-upper)))
     (update-state-payload! s inbounds? (bv 0 8))
     (set-return! s 0)]))


(define (spec-sys_run_enclave s eid)
  (cond
    [(state-enclave-mode s)
     (set-return! s (- keystone:EINVAL))]
    [(! (eid-valid? eid))
     (set-return! s (- keystone:EINVAL))]
    [(&& (! (equal? ((state-enclave.status s) eid) (bv keystone:ENCLAVE_IDLE 64)))
         (! (equal? ((state-enclave.status s) eid) (bv keystone:ENCLAVE_FRESH 64))))
     (set-return! s (- keystone:EINVAL))]
    [else
     (set-state-enclave-mode! s #t)
     (set-state-current-enclave! s eid)
     (update-state-enclave.status! s (list eid) (bv keystone:ENCLAVE_RUNNING 64))
     ; TODO: update registers
     (set-return! s 0)]))


(define (spec-sys_exit_enclave s)
  (cond
    [(! (state-enclave-mode s))
     (set-return! s (- keystone:EINVAL))]
    [else
     (define eid (state-current-enclave s))
     (set-state-enclave-mode! s #f)
     (update-state-enclave.status! s (list eid) (bv keystone:ENCLAVE_IDLE 64))
     (set-state-current-enclave! s (bv -1 eid_t))
     (set-return! s 0)]))

(define (spec-sys_resume_enclave s eid)
  (cond
    [(state-enclave-mode s)
     (set-return! s (- keystone:EINVAL))]
    [(! (eid-valid? eid))
     (set-return! s (- keystone:EINVAL))]
    [(! (equal? ((state-enclave.status s) eid) (bv keystone:ENCLAVE_IDLE 64)))
     (set-return! s (- keystone:EINVAL))]
    [else
     (set-state-enclave-mode! s #t)
     (set-state-current-enclave! s eid)
     (update-state-enclave.status! s (list eid) (bv keystone:ENCLAVE_RUNNING 64))
     (set-return! s 0)]))
