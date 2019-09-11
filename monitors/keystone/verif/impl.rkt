#lang rosette/safe

(require
  "state.rkt"
  serval/lib/core
  (prefix-in keystone: "generated/monitors/keystone/verif/asm-offsets.rkt"))

(provide (all-defined-out))


(define (mregions-abstract mregions)
  (define block-enclave-mode (find-block-by-name mregions 'enclave_mode))
  (define block-current-enclave (find-block-by-name mregions 'current_enclave))
  (define block-payload (find-block-by-name mregions '_payload_start))
  (define block-enclaves (find-block-by-name mregions 'enclaves))

  (state
    ; enclave-mode
    (! (bvzero? (mblock-iload block-enclave-mode null)))
    ; current-enclave
    (mblock-iload block-current-enclave null)
    ; payload
    (lambda (offset) (mblock-iload block-payload (list offset)))
    ; regs
    (zero-regs)
    ; enclave.status
    (lambda (eid) (mblock-iload block-enclaves (list eid 'status)))
    ; enclave.entry
    (lambda (eid) (mblock-iload block-enclaves (list eid 'entry)))
    ; enclave.secure-lower
    (lambda (eid) (mblock-iload block-enclaves (list eid 'secure_lower)))
    ; enclave.secure-upper
    (lambda (eid) (mblock-iload block-enclaves (list eid 'secure_upper)))
    ; enclave.shared-lower
    (lambda (eid) (mblock-iload block-enclaves (list eid 'shared_lower)))
    ; enclave.shared-upper
    (lambda (eid) (mblock-iload block-enclaves (list eid 'shared_upper)))
  ))


(define (mregions-invariants mregions)
  (define block-enclave-mode (find-block-by-name mregions 'enclave_mode))
  (define block-current-enclave (find-block-by-name mregions 'current_enclave))
  (define block-enclaves (find-block-by-name mregions 'enclaves))
  (define enclave-mode (mblock-iload block-enclave-mode null))
  (define current-enclave (mblock-iload block-current-enclave null))

  (define (eid->secure_lower eid)
    (mblock-iload block-enclaves (list eid 'secure_lower)))
  (define (eid->secure_upper eid)
    (mblock-iload block-enclaves (list eid 'secure_upper)))
  (define (eid->shared_lower eid)
    (mblock-iload block-enclaves (list eid 'shared_lower)))
  (define (eid->shared_upper eid)
    (mblock-iload block-enclaves (list eid 'shared_upper)))
  (define (eid->status eid)
    (mblock-iload block-enclaves (list eid 'status)))
  (define (eid-free? eid)
    (bveq (eid->status eid) (bv keystone:ENCLAVE_FREE 64)))

  (define-symbolic eid eid_t)

  (&&
    ; enclave mode => current enclave is valid
    (=> (bitvector->bool enclave-mode)
        (&& (eid-valid? current-enclave)
            (! (eid-free? current-enclave))))
    ; secure_lower|upper form a valid region
    (forall (list eid)
            (=> (&& (eid-valid? eid) (! (eid-free? eid)))
                (region-valid? (eid->secure_lower eid) (eid->secure_upper eid))))

    (forall (list eid)
            (=> (&& (eid-valid? eid) (! (eid-free? eid)))
                (region-valid? (eid->shared_lower eid) (eid->shared_upper eid))))))
