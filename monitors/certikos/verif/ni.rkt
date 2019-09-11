#lang rosette/safe

(require
  serval/lib/unittest
  serval/lib/core
  "state.rkt"
  "spec.rkt"
  "invariants.rkt"
  (only-in racket/base exn:fail? struct-copy string-append parameterize)
  (prefix-in certikos: "generated/monitors/certikos/verif/asm-offsets.rkt")
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit)

(provide (all-defined-out))

(define (active u s)
  (equal? u (state-current-pid s)))

(define (inactive u s)
  (&& (not (equal? u (state-current-pid s)))
      (pid-valid? u)
      (equal? ((state-proc.state s) u) (bv certikos:PROC_STATE_RUN 64))))

(define (unwinding u s t)
  (define-symbolic q pid page offset (bitvector 64))
  (&&
    (equal? ((state-proc.upper s) u) ((state-proc.upper t) u))
    (equal? ((state-proc.lower s) u) ((state-proc.lower t) u))
    (equal? ((state-proc.state s) u) ((state-proc.state t) u))
    (equal? ((state-proc.owner s) u) ((state-proc.owner t) u))
    (equal? ((state-proc.next s) u) ((state-proc.next t) u))
    (equal? ((state-proc.saved-regs s) u) ((state-proc.saved-regs t) u))
    (equal? (active u s) (active u t))
    (forall (var pid)
      (=> (pid-valid? pid)
        (equal?
          (proc-parent? s u pid)
          (proc-parent? t u pid))))
    (forall (var page offset)
      (=> (&& (bvuge page ((state-proc.lower s) u))
              (bvult page ((state-proc.upper s) u))
              (poffset-valid? offset))
        (equal? ((state-pages s) page offset) ((state-pages t) page offset))))
    (forall (var pid)
      (=> (&& (pid-valid? pid) (proc-parent? s u pid))
        (equal? ((state-proc.state s) pid) ((state-proc.state t) pid))))
    (=> (active u s)
      (&& (equal? (state-regs s) (state-regs t))))))

(define (spawn-unwinding u s t)
  (define-symbolic q pid page offset (bitvector 64))
  (define parent ((state-proc.owner s) u))
  (&&
    (equal? ((state-proc.upper s) parent) ((state-proc.upper t) parent))
    (equal? ((state-proc.lower s) parent) ((state-proc.lower t) parent))
    (equal? ((state-proc.state s) parent) ((state-proc.state t) parent))
    (equal? ((state-proc.next s) parent) ((state-proc.next t) parent))
    (equal? (active parent s) (active parent t))
    (equal? (proc-parent? s parent u) (proc-parent? t parent u))))

(define (check-spawn-unwinding)
  ; Sanity check on spawn unwinding
  ; This ensures that spawn leaks no _more_ information
  ; than what the parent can observe.
  (define-symbolic* u parent (bitvector 64))
  (define s (make-havoc-state))
  (define t (make-havoc-state))

  (define pre (&& (unwinding parent s t)
                  (pid-valid? u)
                  (not (proc-runnable? s u))
                  (proc-parent? s parent u)))

  (check-unsat? (verify (assert (=> pre (spawn-unwinding u s t))))))

(define (observe u s)
  (if (active u s)
      (state-regs s)
      #f))

(define (verify-unwinding-symmetry)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define-symbolic* u (bitvector 64))
  (check-unsat? (verify (assert (=> (unwinding u s t) (unwinding u t s))))))

(define (verify-unwinding-reflexivity)
  (define s (make-havoc-state))
  (define-symbolic* u (bitvector 64))
  (check-unsat? (verify (assert (unwinding u s s)))))

(define (verify-unwinding-transitivity)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define v (make-havoc-state))
  (define-symbolic* u (bitvector 64))
  (check-unsat? (verify (assert
    (=> (&& (unwinding u s t) (unwinding u t v))
        (unwinding u s v))))))

(define (check-observe-consistency)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define-symbolic* u (bitvector 64))
  (check-unsat? (verify (assert (=> (unwinding u s t) (equal? (observe u s) (observe u t)))))))

(define (verify-unwinding-negatable)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define-symbolic* u (bitvector 64))
  (check-sat? (solve (assert (not (unwinding u s t))))))

(define (verify-confidentiality spec [args null])
  ; If two indistinguishable active states take a step to two inactive states, then those inactive
  ; states are indistinguishable.
  (define-symbolic* u (bitvector 64))
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define old-s (state-copy s))
  (define old-t (state-copy t))

  (apply spec s args)
  (apply spec t args)

  (define pre (&& (spec-invariants old-s)
                  (spec-invariants old-t)
                  (active u old-s)
                  (active u old-t)
                  (inactive u s)
                  (inactive u t)
                  (unwinding u old-s old-t)))

  (define post (unwinding u s t))
  (check-sat? (solve (assert #t)))
  (check-unsat? (verify (assert (=> pre post)))))

(define (verify-confidentiality-restore spec [args null])
  ; If two indistinguishable inactive states take a step to two active states, then those active
  ; states are indistinguishable
  (define-symbolic* u (bitvector 64))
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define old-s (state-copy s))
  (define old-t (state-copy t))

  (apply spec s args)
  (apply spec t args)

  (define pre (&& (spec-invariants old-s)
                  (spec-invariants old-t)
                  (inactive u old-s)
                  (inactive u old-t)
                  (active u s)
                  (active u t)
                  (unwinding u old-s old-t)))

  (define post (unwinding u s t))
  (check-sat? (solve (assert #t)))
  (check-unsat? (verify (assert (=> pre post)))))


(define (check-generalized-confidentiality spec [args null])
  ; Two indistinguishable active states always take a step to indistinguishable states.
  (define-symbolic* u (bitvector 64))
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define old-s (state-copy s))
  (define old-t (state-copy t))

  (apply spec s args)
  (apply spec t args)

  (define pre (&& (spec-invariants old-s)
                  (spec-invariants old-t)
                  (active u old-s)
                  (active u old-t)
                  (unwinding u old-s old-t)))

  (define post (unwinding u s t))
  (check-sat? (solve (assert #t)))
  (check-unsat? (verify (assert (=> pre post)))))


(define (verify-integrity spec [args null])
  ; "If an inactive state takes a step to another inactive state, then those states are
  ; indistinguishable."
  (define-symbolic* u (bitvector 64))

  (define s (make-havoc-state))
  (define old-s (state-copy s))

  (apply spec s args)

  (define pre (&& (spec-invariants old-s)
                      (inactive u old-s)
                      (inactive u s)))

  (define post (unwinding u old-s s))

  (check-sat? (solve (assert #t)))
  (check-unsat? (verify (assert (=> pre post)))))

(define (buggy-yield s)
  (define old-current (state-current-pid s))
  (define old-lower ((state-proc.lower s) old-current))
  (spec-sys_yield s)
  (define new-current (state-current-pid s))
  (update-state-proc.lower! s (list new-current) old-lower))

(define (buggy-yield2 s)
  (define old-current (state-current-pid s))
  (spec-sys_yield s)
  (define new-current (state-current-pid s))
  (define new-lower ((state-proc.lower s) new-current))
  (update-state-proc.lower! s (list old-current) new-lower))

(define-syntax-rule (ni-case+ name op args)
 (begin
  (test-case+ (string-append name " integrity") (verify-integrity op args))
  (test-case+ (string-append name " confidentiality") (verify-confidentiality op args))
  (test-case+ (string-append name " confidentiality-restore") (verify-confidentiality-restore op args))
  (test-case+ (string-append name " generalized-confidentiality") (check-generalized-confidentiality op args))))


(define certikos-ni-tests
  (test-suite+ "certikos NI tests"

    (test-case+ "observe consistency" (check-observe-consistency))
    (test-case+ "unwinding negatable" (verify-unwinding-negatable))

    (test-case+ "unwinding symmetry" (verify-unwinding-symmetry))
    (test-case+ "unwinding reflexivity" (verify-unwinding-reflexivity))
    (test-case+ "unwinding transitivity" (verify-unwinding-transitivity))

    (ni-case+ "All together" spec-step (list (make-choice)))

    ; (test-case+ "sanity spawn unwinding check" (check-spawn-unwinding))

    ; Counterexamples are expensive to compute for negative testing. Temporarily change NR_PROCS to 4
    ; for these tests so that they fail in a reasonable amount of time
    (test-case+ "buggy-yield confidentiality-restore" (check-exn exn:fail?
      (thunk (parameterize ([nr-procs (bv 4 64)])
        (verify-confidentiality-restore buggy-yield)))))
    (test-case+ "buggy-yield2 confidentiality" (check-exn exn:fail?
      (thunk (parameterize ([nr-procs (bv 4 64)])
        (verify-confidentiality buggy-yield2)))))
    (test-case+ "buggy-yield2 generalized-confidentiality" (check-exn exn:fail?
      (thunk (parameterize ([nr-procs (bv 4 64)])
        (check-generalized-confidentiality buggy-yield2)))))
    ; (test-case+ "buggy-interfere integrity" (check-exn exn:fail?
    ;   (thunk (parameterize ([nr-procs (bv 4 64)])
    ;     (verify-integrity spec-buggy-integrity (list (make-bv64) (make-bv64) (make-bv64)))))))
  ))

(module+ test
  (time (run-tests certikos-ni-tests)))
