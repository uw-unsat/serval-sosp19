#lang rosette/safe

(require
  serval/lib/unittest
  serval/lib/core
  (prefix-in serval: serval/spec/ni)
  "state.rkt"
  "spec.rkt"
  "invariants.rkt"
  (only-in racket/base struct-copy)
  (prefix-in komodo: "generated/monitors/komodo/verif/asm-offsets.rkt")
  (only-in rosette/lib/angelic choose*)
)

(provide (all-defined-out))

(struct os-domain () #:transparent)
(struct entry-domain () #:transparent)
(struct enclave-domain (obs) #:transparent)

(struct exit-domain (enc) #:transparent)
(struct insecure-domain () #:transparent)

(define (fresh-domain)
  (define-symbolic* obs enc (bitvector 64))
  (choose*
    (os-domain)
    (entry-domain)
    (enclave-domain obs)
    (exit-domain enc)
    (insecure-domain)
  ))

(define (fresh-action)
  (choose*
    'kom_smc_query
    'kom_smc_get_phys_pages
    'kom_smc_init_addrspace
    'kom_smc_init_dispatcher
    'kom_smc_init_l2ptable
    'kom_smc_init_l3ptable
    'kom_smc_map_secure
    'kom_smc_map_insecure
    'kom_smc_remove
    'kom_smc_finalise
    'kom_smc_stop
    'kom_smc_enter
    'kom_smc_resume
    'kom_svc_exit
    'insecure_read
    'insecure_write
    'kom_handle_trap
  ))

(define (flowsto u v)
  (cond
    [(equal? u v) #t]

    [(insecure-domain? u) #t]
    [(insecure-domain? v) #t]

    [(os-domain? u)
      (entry-domain? v)]

    [(entry-domain? u) #t]
    [(exit-domain? u) #t]

    [(enclave-domain? u) (if (exit-domain? v) (bveq (enclave-domain-obs u) (exit-domain-enc v)) #f)]

    [else #f]))

(define (unwinding u s t)
  (cond
    [(os-domain? u) (os-equiv s t)]
    [(entry-domain? u) (os-equiv s t)]
    [(enclave-domain? u) (enc-equiv (enclave-domain-obs u) s t)]
    [(exit-domain? u) (enc-equiv (exit-domain-enc u) s t)]
    [(insecure-domain? u) (insecure-equiv s t)]
    [else (assert #f)]))

(define (dom a s)
  (if (state-enclave-mode s)
    (cond
      [(equal? a 'kom_svc_exit) (exit-domain (state-current-addrspace s))]
      [(equal? a 'kom_handle_trap) (exit-domain (state-current-addrspace s))]
      [(equal? a 'insecure_write) (insecure-domain)]
      [(equal? a 'insecure_read) (insecure-domain)]
      [else (enclave-domain (state-current-addrspace s))])
    (cond
      [(equal? a 'insecure_read) (insecure-domain)]
      [(equal? a 'insecure_write) (insecure-domain)]
      [(equal? a 'kom_smc_enter) (entry-domain)]
      [(equal? a 'kom_smc_resume) (entry-domain)]
      [else (os-domain)])))

(define (insecure-equiv s1 s2)
  (define-symbolic pageno offset (bitvector 64))
  (forall (list pageno offset)
    (=> (&& (insecure-page-valid? pageno)
            (page-index-valid? offset))
      (equal? ((state-insecure-pages s1) pageno offset)
              ((state-insecure-pages s2) pageno offset)))))

(define (enc-equiv obs s1 s2)
  (define (enc-valid? st)
    (&& (page-typed? st obs komodo:KOM_PAGE_ADDRSPACE)
        (addrspace-state? st obs komodo:KOM_ADDRSPACE_FINAL)))
  (define (is-current? st)
    (&& (bveq obs (state-current-addrspace st))
        (state-enclave-mode st)))
  (define (page-owned? st pageno)
    (&& (page-valid? pageno)
        (! (page-free? st pageno))
        (bveq obs ((state-pagedb.addrspace st) pageno))))

  (define-symbolic pageno index (bitvector 64))
  (&&
    (equal? (state-enclave-mode s1) (state-enclave-mode s2))
    (<=> (is-current? s1) (is-current? s2))
    (=> (is-current? s1)
      (&& (equal? (state-regs s1) (state-regs s2))
          (equal? (state-current-dispatcher s1) (state-current-dispatcher s2))))
    (<=> (enc-valid? s1) (enc-valid? s2))
    (=> (enc-valid? s1)
     (&&
      ; Enclaves can observe which pages they own
      (forall (list pageno)
        (=> (page-valid? pageno)
          (<=> (page-owned? s1 pageno) (page-owned? s2 pageno))))

      ; Enclaves can see the type of pages they own
      (forall (list pageno)
        (=> (page-owned? s1 pageno)
          (bveq ((state-pagedb.type s1) pageno) ((state-pagedb.type s2) pageno))))

      ; Enclaves can observe the contents of each page they own
      (forall (list pageno index)
        (=> (&& (page-owned? s1 pageno)
                (page-index-valid? index))
          (bveq ((state-pages s1) pageno index) ((state-pages s2) pageno index))))

      (forall (list pageno index)
        (=> (&& (page-owned? s1 pageno)
                (page-index-valid? index))
          (&& (equal? ((state-pgtable-pn s1) pageno index) ((state-pgtable-pn s2) pageno index))
              (equal? ((state-pgtable-secure s1) pageno index) ((state-pgtable-secure s2) pageno index))
              (equal? ((state-pgtable-present s1) pageno index) ((state-pgtable-present s2) pageno index))
              (equal? ((state-pgtable-perm s1) pageno index) ((state-pgtable-perm s2) pageno index)))))
    ))))

; When do two states appear equivalent to the OS?
(define (os-equiv s1 s2)
  (define-symbolic pageno index (bitvector 64))
  (&&
    ; Insecure pages equiv
    (insecure-equiv s1 s2)
    ; The OS knows who is running
    (equal? (state-current-dispatcher s1) (state-current-dispatcher s2))
    (equal? (state-current-addrspace s1) (state-current-addrspace s2))
    ; The OS can tell if the machine is in enclave mode
    (equal? (state-enclave-mode s1) (state-enclave-mode s2))
    ; The OS can see its own saved state
    (equal? (state-host-state s1) (state-host-state s2))
    ; The OS can see the machine registers if not in enclave mode
    (=> (! (state-enclave-mode s1))
      (equal? (state-regs s1) (state-regs s2)))
    ; The OS can see the type of each page
    (forall (list pageno)
      (=> (page-valid? pageno)
        (bveq ((state-pagedb.type s1) pageno)
              ((state-pagedb.type s2) pageno))))
    ; The OS can see who owns each page
    (forall (list pageno)
      (=> (page-valid? pageno)
        (bveq ((state-pagedb.addrspace s1) pageno)
              ((state-pagedb.addrspace s2) pageno))))
    ; The OS can observe the _contents_ of all L{1,2,3}PTABLE pages
    (forall (list pageno index)
      (=> (&& (page-valid? pageno)
              (page-index-valid? index)
              (|| (page-typed? s1 pageno komodo:KOM_PAGE_L1PTABLE)
                  (page-typed? s1 pageno komodo:KOM_PAGE_L2PTABLE)
                  (page-typed? s1 pageno komodo:KOM_PAGE_L3PTABLE)))
        (&& (bveq ((state-pages s1) pageno index) ((state-pages s2) pageno index))
            (equal? ((state-pgtable-pn s1) pageno index) ((state-pgtable-pn s2) pageno index))
            (equal? ((state-pgtable-secure s1) pageno index) ((state-pgtable-secure s2) pageno index))
            (equal? ((state-pgtable-present s1) pageno index) ((state-pgtable-present s2) pageno index))
            (equal? ((state-pgtable-perm s1) pageno index) ((state-pgtable-perm s2) pageno index)))))


    ; The OS can observe the state,l1pt, and refcount fields of each addrspace page
    (forall (list pageno)
      (=> (&& (page-valid? pageno)
              (page-typed? s1 pageno komodo:KOM_PAGE_ADDRSPACE))
        (&& (bveq (state-addrspace.state s1 pageno)
                  (state-addrspace.state s2 pageno))
            (bveq (state-addrspace.refcount s1 pageno)
                  (state-addrspace.refcount s2 pageno))
            (bveq (state-addrspace.l1pt s1 pageno)
                  (state-addrspace.l1pt s2 pageno)))))

    ; The OS can observe the entered field of dispatchers
    (forall (list pageno)
        (=> (&& (page-valid? pageno)
                (page-typed? s1 pageno komodo:KOM_PAGE_DISPATCHER))
          (bveq (state-dispatcher.entered s1 pageno)
                (state-dispatcher.entered s2 pageno))))
  ))

(define (verify-unwinding-equiv)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define v (make-havoc-state))
  (define u (fresh-domain))
  (check-unsat? (verify (assert (unwinding u s s))))
  (check-unsat? (verify (assert (=> (unwinding u s t) (unwinding u t s)))))
  (check-unsat? (verify (assert (=> (&& (unwinding u s t) (unwinding u t v)) (unwinding u s v))))))

(define (verify-dom-consistency)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define a (fresh-action))
  (define doma (dom a s))

  (define pre (unwinding doma s t))
  (define post (equal? (dom a s) (dom a t)))

  (check-unsat? (verify (assert (=> pre post)))))

(define (check-flow-consistency)
  (define s (make-havoc-state))
  (define t (make-havoc-state))
  (define a (fresh-action))
  (define u (fresh-domain))

  (check-unsat? (verify (assert
    (=> (unwinding u s t)
      (equal?
        (flowsto (dom a s) u)
        (flowsto (dom a t) u)))))))

(define (verify-weak-step-consistency action spec [args null])
  (serval:check-weak-step-consistency
    #:state-init make-havoc-state
    #:state-copy (lambda (s) (struct-copy state s))
    #:invariants (lambda (s) (apply && (flatten (spec-lemmas s))))
    #:dom dom
    #:u (fresh-domain)
    #:unwinding unwinding
    #:flowsto flowsto
    action
    spec
    args))

(define (verify-local-respect action spec [args null])
  (serval:check-local-respect
    #:state-init make-havoc-state
    #:state-copy (lambda (s) (struct-copy state s))
    #:invariants (lambda (s) (apply && (flatten (spec-lemmas s))))
    #:dom dom
    #:u (fresh-domain)
    #:unwinding unwinding
    #:flowsto flowsto
    action
    spec
    args))

(define komodo-ni-tests
  (test-suite+ "komodo NI tests"

    (test-case+ "unwinding is equivalence"
      (verify-unwinding-equiv))

    (test-case+ "dom consistency"
      (verify-dom-consistency))

    (test-case+ "flow consistency"
      (check-flow-consistency))

    (test-case+ "kom_handle_trap weak step consistency"
      (verify-weak-step-consistency 'kom_handle_trap spec-kom_handle_trap
        (list (make-bv64))))
    (test-case+ "kom_handle_trap local respect"
      (verify-local-respect 'kom_handle_trap spec-kom_handle_trap
        (list (make-bv64))))

    (test-case+ "insecure_read weak step consistency"
      (verify-weak-step-consistency 'insecure_read spec-insecure_read
        (list (make-bv64) (make-bv64))))
    (test-case+ "insecure_read local respect"
      (verify-local-respect 'insecure_read spec-insecure_read
        (list (make-bv64) (make-bv64))))

    (test-case+ "insecure_write weak step consistency"
      (verify-weak-step-consistency 'insecure_write spec-insecure_write
        (list (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "insecure_write local respect"
      (verify-local-respect 'insecure_write spec-insecure_write
        (list (make-bv64) (make-bv64) (make-bv64))))


    (test-case+ "enclave_read weak step consistency"
      (verify-weak-step-consistency 'enclave_read spec-enclave_read
        (list (make-bv64) (make-bv64))))
    (test-case+ "enclave_read local respect"
      (verify-local-respect 'enclave_read spec-enclave_read
        (list (make-bv64) (make-bv64))))

    (test-case+ "enclave_write weak step consistency"
      (verify-weak-step-consistency 'enclave_write spec-enclave_write
        (list (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "enclave_write local respect"
      (verify-local-respect 'enclave_write spec-enclave_write
        (list (make-bv64) (make-bv64) (make-bv64))))


    (test-case+ "kom_smc_query weak step consistency"
      (verify-weak-step-consistency 'kom_smc_query (make-smc-spec spec-kom_smc_query)))
    (test-case+ "kom_smc_query local respect"
      (verify-local-respect 'kom_smc_query (make-smc-spec spec-kom_smc_query)))

    (test-case+ "kom_smc_get_phys_pages weak step consistency"
      (verify-weak-step-consistency 'kom_smc_get_phys_pages (make-smc-spec spec-kom_smc_get_phys_pages)))
    (test-case+ "kom_smc_get_phys_pages local respect"
      (verify-local-respect 'kom_smc_get_phys_pages (make-smc-spec spec-kom_smc_get_phys_pages)))

    (test-case+ "kom_smc_init_addrspace weak step consistency"
      (verify-weak-step-consistency 'kom_smc_init_addrspace (make-smc-spec spec-kom_smc_init_addrspace) (list (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_init_addrspace local respect"
      (verify-local-respect 'kom_smc_init_addrspace (make-smc-spec spec-kom_smc_init_addrspace) (list (make-bv64) (make-bv64))))

    (test-case+ "kom_smc_init_dispatcher weak step consistency"
      (verify-weak-step-consistency 'kom_smc_init_dispatcher (make-smc-spec spec-kom_smc_init_dispatcher) (list (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_init_dispatcher local respect"
      (verify-local-respect 'kom_smc_init_dispatcher (make-smc-spec spec-kom_smc_init_dispatcher) (list (make-bv64) (make-bv64) (make-bv64))))

    (test-case+ "kom_smc_init_l2ptable weak step consistency"
      (verify-weak-step-consistency 'kom_smc_init_l2ptable (make-smc-spec spec-kom_smc_init_l2ptable) (list (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_init_l2ptable local respect"
      (verify-local-respect 'kom_smc_init_l2ptable (make-smc-spec spec-kom_smc_init_l2ptable) (list (make-bv64) (make-bv64) (make-bv64))))

    (test-case+ "kom_smc_init_l3ptable weak step consistency"
      (verify-weak-step-consistency 'kom_smc_init_l3ptable (make-smc-spec spec-kom_smc_init_l3ptable) (list (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_init_l3ptable local respect"
      (verify-local-respect'kom_smc_init_l3ptable (make-smc-spec spec-kom_smc_init_l3ptable) (list (make-bv64) (make-bv64) (make-bv64))))

    (test-case+ "kom_smc_map_secure weak step consistency"
      (verify-weak-step-consistency 'kom_smc_map_secure (make-smc-spec spec-kom_smc_map_secure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_map_secure local respect"
      (verify-local-respect 'kom_smc_map_secure (make-smc-spec spec-kom_smc_map_secure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64))))

    (test-case+ "kom_smc_map_insecure weak step consistency"
      (verify-weak-step-consistency 'kom_smc_map_insecure (make-smc-spec spec-kom_smc_map_insecure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_map_insecure local respect"
      (verify-local-respect 'kom_smc_map_insecure (make-smc-spec spec-kom_smc_map_insecure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))

    (test-case+ "kom_smc_remove weak step consistency"
      (verify-weak-step-consistency 'kom_smc_remove (make-smc-spec spec-kom_smc_remove) (list (make-bv64))))
    (test-case+ "kom_smc_remove weak local respect"
      (verify-local-respect 'kom_smc_remove (make-smc-spec spec-kom_smc_remove) (list (make-bv64))))

    (test-case+ "kom_smc_finalise weak step consistency"
      (verify-weak-step-consistency 'kom_smc_finalise (make-smc-spec spec-kom_smc_finalise) (list (make-bv64))))

    (test-case+ "kom_smc_stop weak step consistency"
      (verify-weak-step-consistency 'kom_smc_stop (make-smc-spec spec-kom_smc_stop) (list (make-bv64))))

    (test-case+ "kom_smc_enter weak step consistency"
      (verify-weak-step-consistency 'kom_smc_enter (make-smc-spec spec-kom_smc_enter) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "kom_smc_enter local respect"
      (verify-local-respect 'kom_smc_enter (make-smc-spec spec-kom_smc_enter) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64))))

    (test-case+ "kom_smc_resume weak step consistency"
      (verify-weak-step-consistency 'kom_smc_resume (make-smc-spec spec-kom_smc_resume) (list (make-bv64))))
    (test-case+ "kom_smc_resume local respect"
      (verify-local-respect 'kom_smc_resume (make-smc-spec spec-kom_smc_resume) (list (make-bv64))))

    (test-case+ "kom_svc_exit weak step consistency"
      (verify-weak-step-consistency 'kom_svc_exit spec-kom_svc_exit (list (make-bv64))))
    (test-case+ "kom_svc_exit local respect"
      (verify-local-respect 'kom_svc_exit spec-kom_svc_exit (list (make-bv64))))

  ))

(module+ test
  (time (run-tests komodo-ni-tests)))
