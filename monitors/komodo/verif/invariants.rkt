#lang rosette/safe

(require
  serval/lib/core
  serval/lib/unittest
  serval/spec/refcnt
  "state.rkt"
  "spec.rkt"
  (only-in racket/base for string-append)
  (prefix-in komodo: "symbols.rkt")
  (prefix-in komodo: "generated/monitors/komodo/verif/asm-offsets.rkt")
)

(provide (all-defined-out))

(define (spec-invariants st)
  (define current-addrspace (state-current-addrspace st))
  (define current-dispatcher (state-current-dispatcher st))
  (define enclave-mode (state-enclave-mode st))
  (define (page-typed? pageno type)
    (&& (page-valid? pageno)
        (bveq ((state-pagedb.type st) pageno) (bv type 64))))
  (define (page-nonfree? pageno)
    (&& (page-valid? pageno)
        (! (bveq ((state-pagedb.type st) pageno) (bv komodo:KOM_PAGE_FREE 64)))))
  (define (page->addrspace pageno)
    ((state-pagedb.addrspace st) pageno))
  (define-symbolic pageno (bitvector 64))
  (list
    ; Every addrspace owns itself
    (forall (list pageno)
      (=> (page-typed? pageno komodo:KOM_PAGE_ADDRSPACE)
        (bveq pageno (page->addrspace pageno))))
    ; The owner of a non-free page is a valid page
    (forall (list pageno)
      (=> (page-nonfree? pageno)
        (page-valid? (page->addrspace pageno))))
    ; The current dispatcher is a valid page
    (page-valid? current-dispatcher)
    ; When in enclave mode, the current dispatcher page is the right type
    (=> enclave-mode
      (&& (page-typed? current-dispatcher komodo:KOM_PAGE_DISPATCHER)
          (bveq current-addrspace (page->addrspace current-dispatcher))
          (addrspace-state? st current-addrspace komodo:KOM_ADDRSPACE_FINAL)))
  ))


; Invariants involving refcnt correctness
(define (spec-refcnt-invariants st)
  (define current-dispatcher (state-current-dispatcher st))
  (define enclave-mode (state-enclave-mode st))
  (define (page-typed? pageno type)
    (&& (page-valid? pageno)
        (bveq ((state-pagedb.type st) pageno) (bv type 64))))
  (define (page-nonfree? pageno)
    (&& (page-valid? pageno)
        (! (bveq ((state-pagedb.type st) pageno) (bv komodo:KOM_PAGE_FREE 64)))))
  (define (page-free? pageno)
    (page-typed? pageno komodo:KOM_PAGE_FREE))
  (define (page->addrspace pageno)
    ((state-pagedb.addrspace st) pageno))
  (define page-refcnt (state-page-refcnt st))
  (define-symbolic pageno (bitvector 64))
  (list
    ; Every addrspace owns itself
    (forall (list pageno)
      (=> (page-typed? pageno komodo:KOM_PAGE_ADDRSPACE)
        (bveq pageno (page->addrspace pageno))))
    ; The owner of a non-free page is a valid page
    (forall (list pageno)
      (=> (page-nonfree? pageno)
        (page-valid? (page->addrspace pageno))))
    ; The current dispatcher is a valid page
    (page-valid? current-dispatcher)
    ; When in enclave mode, the current dispatcher page is the right type
    (=> enclave-mode
      (page-typed? current-dispatcher komodo:KOM_PAGE_DISPATCHER))
    ; Pages that are not an addrspace have zero pages
    (forall (list pageno)
      (=> (&& (page-valid? pageno) (! (page-typed? pageno komodo:KOM_PAGE_ADDRSPACE)))
        (bveq ((refcnt-cnt (state-page-refcnt st)) pageno) (bv 0 64))))
    ; Page reference values are correct
    (forall (list pageno)
      (=> (page-typed? pageno komodo:KOM_PAGE_ADDRSPACE)
         (bveq (state-addrspace.refcount st pageno)
               ((refcnt-cnt (state-page-refcnt st)) pageno))))
    ; Page reference count correctness
    (refcnt-invariants
      page-refcnt
      page-valid? ; owner-valid?
      page-valid? ; object-valid?
      (bv komodo:KOM_SECURE_NPAGES 64) ; max-refs
      (lambda (own obj) (&& (bveq own (page->addrspace obj))
                            (! (page-free? obj))))) ; owned-by?
  ))

(define (spec-pgtable-invariants st)
  (define current-dispatcher (state-current-dispatcher st))
  (define enclave-mode (state-enclave-mode st))
  (define (page-typed? pageno type)
    (&& (page-valid? pageno)
        (bveq ((state-pagedb.type st) pageno) (bv type 64))))
  (define (page->addrspace pageno)
    ((state-pagedb.addrspace st) pageno))

  (define (pgtable-ok? pageno index)
    (&& (page-valid? pageno)
        (page-index-valid? index)
        (page-typed? (page->addrspace pageno) komodo:KOM_PAGE_ADDRSPACE)
        (! (addrspace-state? st (page->addrspace pageno) komodo:KOM_ADDRSPACE_STOPPED))))
  (define (pages pageno index)
    ((state-pages st) pageno index))
  (define (pgtable-present pageno index)
    ((state-pgtable-present st) pageno index))
  (define (pgtable-pn pageno index)
    ((state-pgtable-pn st) pageno index))
  (define (pgtable-perm pageno index)
    ((state-pgtable-perm st) pageno index))
  (define (pgtable-secure pageno index)
    ((state-pgtable-secure st) pageno index))

  (define-symbolic pageno index (bitvector 64))
  (list
    (=> enclave-mode
      (page-typed? current-dispatcher komodo:KOM_PAGE_DISPATCHER))
    ; l1ptable is correct
    (forall (list pageno)
      (=> (&& (page-typed? pageno komodo:KOM_PAGE_ADDRSPACE)
              (! (addrspace-state? st pageno komodo:KOM_ADDRSPACE_STOPPED)))
        (&& (page-typed? (state-addrspace.l1pt st pageno) komodo:KOM_PAGE_L1PTABLE)
            (bveq pageno (page->addrspace (state-addrspace.l1pt st pageno))))))

    ; pgtable pn is synchronized with real page tables
    (forall (list pageno index)
      (=> (&& (pgtable-ok? pageno index)
              (|| (page-typed? pageno komodo:KOM_PAGE_L1PTABLE)
                  (page-typed? pageno komodo:KOM_PAGE_L2PTABLE)))
        (bveq (pages pageno index)
          (if (pgtable-present pageno index)
              (pfn->pte (page->pfn (pgtable-pn pageno index)) (bv komodo:_PAGE_TABLE 64))
              (bv 0 64)))))

    ; pgtable leaves are synchronized with real page tables
    (forall (list pageno index)
      (=> (&& (pgtable-ok? pageno index)
              (page-typed? pageno komodo:KOM_PAGE_L3PTABLE))
        (bveq (pages pageno index)
          (if (pgtable-present pageno index)
              (if (pgtable-secure pageno index)
                  (pfn->pte (page->pfn (pgtable-pn pageno index)) (enclave-prot (pgtable-perm pageno index)))
                  (pfn->pte (insecure_page->pfn (pgtable-pn pageno index)) (enclave-prot (pgtable-perm pageno index))))
              (bv 0 64)))))

    ; L1 points to L2
    (forall (list pageno index)
      (=> (&& (pgtable-ok? pageno index)
              (pgtable-present pageno index)
              (page-typed? pageno komodo:KOM_PAGE_L1PTABLE))
        (&& (page-typed? (pgtable-pn pageno index) komodo:KOM_PAGE_L2PTABLE)
            (bveq (page->addrspace pageno) (page->addrspace (pgtable-pn pageno index))))))

    ; L2 points to L3
    (forall (list pageno index)
      (=> (&& (pgtable-ok? pageno index)
              (pgtable-present pageno index)
              (page-typed? pageno komodo:KOM_PAGE_L2PTABLE))
        (&& (page-typed? (pgtable-pn pageno index) komodo:KOM_PAGE_L3PTABLE)
            (bveq (page->addrspace pageno) (page->addrspace (pgtable-pn pageno index))))))

    ; L3 secure page ok
    (forall (list pageno index)
      (=> (&& (pgtable-ok? pageno index)
              (pgtable-present pageno index)
              (page-typed? pageno komodo:KOM_PAGE_L3PTABLE)
              (pgtable-secure pageno index))
        (&& (page-typed? (pgtable-pn pageno index) komodo:KOM_PAGE_DATA)
            (bveq (page->addrspace pageno) (page->addrspace (pgtable-pn pageno index))))))

    ; L3 insecure page ok
    (forall (list pageno index)
      (=> (&& (pgtable-ok? pageno index)
              (pgtable-present pageno index)
              (page-typed? pageno komodo:KOM_PAGE_L3PTABLE)
              (! (pgtable-secure pageno index)))
        (insecure-page-valid? (pgtable-pn pageno index))))

    ; Pages that are not page tables do not have present entries
    (forall (list pageno index)
      (=> (&& (page-valid? pageno)
              (page-index-valid? index)
              (! (page-typed? pageno komodo:KOM_PAGE_L1PTABLE))
              (! (page-typed? pageno komodo:KOM_PAGE_L2PTABLE))
              (! (page-typed? pageno komodo:KOM_PAGE_L3PTABLE)))
        (&& (! (pgtable-present pageno index))
            (bveq (pgtable-pn pageno index) (bv 0 64)))))

    ; Only leaves have permission bits or secure bit set
    (forall (list pageno index)
      (=> (&& (page-valid? pageno)
              (page-index-valid? index)
              (! (page-typed? pageno komodo:KOM_PAGE_L3PTABLE)))
        (&& (! (pgtable-secure pageno index))
            (bveq (pgtable-perm pageno index) (bv 0 64)))))
  ))

(define (spec-refcnt-lemmas st)
  (define (page-typed? pageno type)
    (&& (page-valid? pageno)
        (bveq ((state-pagedb.type st) pageno) (bv type 64))))
  (define (page-nonfree? pageno)
    (&& (page-valid? pageno)
        (! (bveq ((state-pagedb.type st) pageno) (bv komodo:KOM_PAGE_FREE 64)))))
  (define (page->addrspace pageno)
    ((state-pagedb.addrspace st) pageno))
  (define-symbolic pageno (bitvector 64))
  (list
    (forall (list pageno)
      (=> (page-nonfree? pageno)
        (page-typed? (page->addrspace pageno) komodo:KOM_PAGE_ADDRSPACE)))))

(define (check-refcnt-lemmas)
  (define state (make-havoc-state))
  (define pre (apply && (flatten (spec-refcnt-invariants state))))
  (check-equal? (asserts) null)
  (for ([p (spec-refcnt-lemmas state)])
    (check-unsat? (verify (assert (=> pre p))))))

(define (verify-invariant inv spec [args null])
  (define st (make-havoc-state))
  (define pre (&& (apply && (flatten (inv st)))
                  (apply && (flatten (spec-refcnt-lemmas st)))))
  (check-asserts-only (apply spec st args))
  (define post (check-asserts (inv st)))
  (check-equal? (asserts) null)
  (for ([p (flatten post)])
    (check-unsat? (verify (assert (=> pre p))))))

(define (check-refcnt-invariants spec [args null])
  (define st (make-havoc-state))
  (define pre (apply && (flatten (spec-refcnt-invariants st))))
  (check-asserts-only (apply spec st args))
  (define post (check-asserts (spec-refcnt-invariants st)))
  (check-equal? (asserts) null)
  (for ([p (flatten post)])
    (check-unsat? (verify (assert (=> pre p))))))

(define-syntax-rule (verify-invariants name spec args)
  (begin
    (test-case+ (string-append name " spec invariants") (verify-invariant spec-invariants spec args))
    (test-case+ (string-append name " refcnt invariants") (check-refcnt-invariants spec args))
    (test-case+ (string-append name " pgtable invariants") (verify-invariant spec-pgtable-invariants spec args))
))

(define (spec-lemmas st)
  (list
    (spec-refcnt-lemmas st)
    (spec-invariants st)))

; Ensure that the pgtable invariants are strong enough to prove
; that a secure page walk will resolve to a page owned by the enclave
(define (check-pgwalk-ok)
  (define s (make-havoc-state))

  (define-symbolic* l1pt_index l2pt_index l3pt_index (bitvector 64))
  (define pgwalk (enclave-pgwalk-secure s l1pt_index l2pt_index l3pt_index))

  (define pre (&& (apply && (flatten (spec-refcnt-lemmas s)))
                  (apply && (flatten (spec-invariants s)))
                  (apply && (flatten (spec-pgtable-invariants s)))
                  (state-enclave-mode s)
                  (car pgwalk)))

  (define post (&& (page-valid? (cdr pgwalk))
                   (page-typed? s (cdr pgwalk) komodo:KOM_PAGE_DATA)
                   (bveq (state-current-addrspace s) ((state-pagedb.addrspace s) (cdr pgwalk)))))
  (check-equal? (asserts) null)
  (check-unsat? (verify (assert (=> pre post)))))

(define spec-tests
  (test-suite+ "komodo spec tests"

    (test-case+ "check pgwalk ok" (check-pgwalk-ok))

    (test-case+ "komodo check refcnt lemmas" (check-refcnt-lemmas))

    (expand-spec-tests verify-invariants)

))

(module+ test
  (time (run-tests spec-tests)))
