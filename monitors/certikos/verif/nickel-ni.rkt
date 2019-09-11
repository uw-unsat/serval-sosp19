#lang rosette/safe

(require
  serval/lib/unittest
  serval/lib/core
  (prefix-in serval: serval/spec/ni)
  "state.rkt"
  "spec.rkt"
  "invariants.rkt"
  (only-in racket/base exn:fail? struct-copy string-append parameterize)
  (prefix-in certikos: "generated/monitors/certikos/verif/asm-offsets.rkt")
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  rosette/lib/angelic
)

(struct yield-domain (pid) #:transparent)
(struct spawn-domain (parent child) #:transparent)
(struct regular-domain (pid) #:transparent)
(struct antiyield-domain (pid) #:transparent)

(define (fresh-domain)
  (define-symbolic* pid child (bitvector 64))
  (choose*
    (yield-domain pid)
    (spawn-domain pid child)
    (antiyield-domain pid)
    (regular-domain pid)))

(define (active u s)
  (equal? u (state-current-pid s)))

(define (dom a s)
  (define spec (car a))
  (define args (cdr a))
  (define current (state-current-pid s))
  (cond
    [(eq? spec spec-sys_yield) (yield-domain current)]
    [(eq? spec spec-sys_spawn)
      (define child-pid (list-ref args 2))
      (if (&& (pid-valid? child-pid)
              (proc-parent? s current child-pid)
              (not (proc-runnable? s child-pid)))
        (spawn-domain current child-pid)
        (regular-domain current))]
    [else (regular-domain current)]))

(define (flowsto u v)
  (cond
    ; yield interferes with everyone _except_ others' Antiyield domains
    [(yield-domain? u)
      (cond
        [(antiyield-domain? v) (equal? (antiyield-domain-pid v) (yield-domain-pid u))]
        [else #t])]

    ; Any domain except yield can interfere with antiyield
    [(antiyield-domain? v) #t]

    ; Spawn(parent, child) interferes with
    ;   yield(parent) yield(child)
    ;   regular(parent) regular(child)
    ;   spawn(parent, _) spawn(child, _)
    [(spawn-domain? u)
      (define parent (spawn-domain-parent u))
      (define child (spawn-domain-child u))
      (define reader (cond
        [(yield-domain? v) (yield-domain-pid v)]
        [(regular-domain? v) (regular-domain-pid v)]
        [(spawn-domain? v) (spawn-domain-parent v)]))
      (|| (equal? reader parent) (equal? reader child))]

    ; Regular(pid) interferes with
    ;   Yield(pid) Regular(pid) Spawn(pid, _)
    [(regular-domain? u)
      (define pid (regular-domain-pid u))
      (cond
        [(yield-domain? v) #f]
        [(regular-domain? v) (equal? pid (regular-domain-pid v))]
        [(spawn-domain? v) (equal? pid (spawn-domain-parent v))])]))


(define (unwinding dom s t)
  (define d dom)
   (cond
    [(spawn-domain? d) (spawn-eqv (spawn-domain-parent d) (spawn-domain-child d) s t)]
    [(yield-domain? d) (yield-eqv (yield-domain-pid d) s t)]
    [(regular-domain? d) (eqv (regular-domain-pid d) s t)]
    [(antiyield-domain? d) (antiyield-eqv (antiyield-domain-pid d) s t)]))

(define (eqv u s t)
  (define-symbolic q pid page offset (bitvector 64))
  (=> (pid-valid? u)
    (&&
      (equal? (state-current-pid s) (state-current-pid t))
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
        (&& (equal? (state-regs s) (state-regs t)))))))

(define (antiyield-eqv u s t)
  (define-symbolic q pid page offset (bitvector 64))
  (=> (pid-valid? u)
    (&&
      (equal? ((state-proc.upper s) u) ((state-proc.upper t) u))
      (equal? ((state-proc.lower s) u) ((state-proc.lower t) u))
      (equal? ((state-proc.state s) u) ((state-proc.state t) u))
      (equal? ((state-proc.owner s) u) ((state-proc.owner t) u))
      (equal? ((state-proc.next s) u) ((state-proc.next t) u))
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
          (equal? ((state-proc.state s) pid) ((state-proc.state t) pid)))))))

(define (verify-dom-respect spec [args null])
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define u (fresh-domain))

  (define dom-a-s (dom (cons spec args) s))
  (define dom-a-t (dom (cons spec args) s))

  (define pre (&& (spec-invariants s)
                  (spec-invariants t)
                  (unwinding u s t)))
  (define post (<=> (flowsto dom-a-s u)
                    (flowsto dom-a-t u)))
  (check-unsat? (verify (assert (=> pre post)))))


(define (verify-dom-consistency spec [args null])
  (define s (make-havoc-state))
  (define t (make-havoc-state))

  (define dom-a-s (dom (cons spec args) s))
  (define dom-a-t (dom (cons spec args) t))

  (define pre (&& (spec-invariants s)
                  (spec-invariants t)
                  (unwinding dom-a-s s t)))

  (define post (equal? dom-a-s dom-a-t))
  (check-unsat? (verify (assert (=> pre post)))))


(define (spawn-eqv u child s t)
  (=> (&& (pid-valid? u) (pid-valid? child))
    (&&
      (equal? (state-current-pid s) (state-current-pid t))
      (equal? (active u s) (active u t))
      (equal? ((state-proc.upper s) u) ((state-proc.upper t) u))
      (equal? ((state-proc.lower s) u) ((state-proc.lower t) u))
      (equal? ((state-proc.state s) u) ((state-proc.state t) u))
      (equal? ((state-proc.next s) u) ((state-proc.next t) u))
      (equal? (proc-parent? s u child) (proc-parent? t u child))
      (=> (proc-parent? s u child)
        (equal? ((state-proc.state s) child) ((state-proc.state t) child))))))


(define (yield-eqv u s t)
  (=> (pid-valid? u)
    (&&
      (equal? (state-current-pid s) (state-current-pid t))
      (equal? ((state-proc.next s) u) ((state-proc.next t) u)))))

(define (verify-unwinding-symmetry)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define u (fresh-domain))
  (check-unsat? (verify (assert (=> (unwinding u s t) (unwinding u t s))))))

(define (verify-unwinding-reflexivity)
  (define s (make-havoc-state))
  (define u (fresh-domain))
  (check-unsat? (verify (assert (unwinding u s s)))))

(define (verify-unwinding-transitivity)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define v (make-havoc-state))
  (define u (fresh-domain))
  (check-unsat? (verify (assert
    (=> (&& (unwinding u s t) (unwinding u t v))
        (unwinding u s v))))))

(define (verify-unwinding-negatable)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define u (fresh-domain))
  (check-sat? (solve (assert (not (unwinding u s t))))))

(define (verify-weak-step-consistency spec [args null])
  (serval:check-local-respect
    #:state-init make-havoc-state
    #:state-copy state-copy
    #:invariants spec-invariants
    #:dom dom
    #:u (fresh-domain)
    #:unwinding unwinding
    #:flowsto flowsto
    (cons spec args)
    spec
    args))

(define (verify-local-respect spec [args null])
  (serval:check-local-respect
    #:state-init make-havoc-state
    #:state-copy state-copy
    #:invariants spec-invariants
    #:dom dom
    #:u (fresh-domain)
    #:unwinding unwinding
    #:flowsto flowsto
    (cons spec args)
    spec
    args))

(define-syntax-rule (ni-case+ name op args)
 (begin
  (test-case+ (string-append name " weak-step-consistency") (verify-weak-step-consistency op args))
  (test-case+ (string-append name " local-respect") (verify-local-respect op args))
  (test-case+ (string-append name " dom consistency") (verify-dom-consistency op args))
  (test-case+ (string-append name " dom respect") (verify-dom-respect op args))
 ))

(define certikos-ni-tests
  (test-suite+ "certikos NI tests"

    (test-case+ "unwinding negatable" (verify-unwinding-negatable))
    (test-case+ "unwinding symmetry" (verify-unwinding-symmetry))
    (test-case+ "unwinding reflexivity" (verify-unwinding-reflexivity))
    (test-case+ "unwinding transitivity" (verify-unwinding-transitivity))

    (ni-case+ "spec-write-regs" spec-write-regs (list (make-havoc-regs)))
    (ni-case+ "spec-write" spec-write (list (make-bv64) (make-bv64) (make-bv64)))
    (ni-case+ "spec-read" spec-read (list (make-bv64) (make-bv64)))
    (ni-case+ "spec-write-regs" spec-write-regs (list (make-havoc-regs)))
    (ni-case+ "spawn" spec-sys_spawn (list (make-bv64) (make-bv64) (make-bv64)))
    (ni-case+ "get_quota" spec-sys_get_quota null)
    (ni-case+ "getpid" spec-sys_getpid null)
    (ni-case+ "yield" spec-sys_yield null)

  ))

(module+ test
  (time (run-tests certikos-ni-tests)))
