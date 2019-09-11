#lang rosette/safe

(require
  serval/lib/core
  (prefix-in keystone: "generated/monitors/keystone/verif/asm-offsets.rkt"))

(provide (all-defined-out))


(define eid_t (bitvector 64))

(struct regs
  (ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
  satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie)
  #:transparent)

(define (zero-regs)
  (regs (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64)
        (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64)
        (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64)
        (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64)
        (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64) (bv 0 64)
        (bv 0 64) (bv 0 64)))

(struct state (enclave-mode
               current-enclave
               payload
               regs
               enclave.status
               enclave.entry
               enclave.secure-lower
               enclave.secure-upper
               enclave.shared-lower
               enclave.shared-upper)
  #:transparent #:mutable
  #:methods gen:equal+hash
  [(define (equal-proc s t equal?-recur)
     (define-symbolic offset i64)
     (define-symbolic eid eid_t)
     (&& (equal?-recur (state-enclave-mode s) (state-enclave-mode t))
         (equal?-recur (state-current-enclave s) (state-current-enclave t))
         ; payload
         (forall (list offset)
                 (=> (offset-valid? offset)
                     (bveq ((state-payload s) offset) ((state-payload t) offset))))
         (equal?-recur (state-regs s) (state-regs t))
         (forall (list eid)
                 (=> (eid-valid? eid)
                     (&& (equal?-recur ((state-enclave.status s) eid) ((state-enclave.status t) eid))
                         (equal?-recur ((state-enclave.entry s) eid) ((state-enclave.entry t) eid))
                         (equal?-recur ((state-enclave.secure-lower s) eid) ((state-enclave.secure-lower t) eid))
                         (equal?-recur ((state-enclave.secure-upper s) eid) ((state-enclave.secure-upper t) eid))
                         (equal?-recur ((state-enclave.shared-lower s) eid) ((state-enclave.shared-lower t) eid))
                         (equal?-recur ((state-enclave.shared-upper s) eid) ((state-enclave.shared-upper t) eid)))))
   ))
   (define (hash-proc s hash-recur) 1)
   (define (hash2-proc s hash2-recur) 2)]
  ; pretty-print function
  #:methods gen:custom-write
  [(define (write-proc s port mode)
     (define-symbolic %eid eid_t)
     (fprintf port "(state")
     (fprintf port "\n  enclave-mode . ~a" (state-enclave-mode s))
     (fprintf port "\n  current-enclave . ~a" (state-current-enclave s))
     (fprintf port "\n  enclave.status . ~a~a~a" (list %eid) "~>" ((state-enclave.status s) %eid))
     (fprintf port "\n  enclave.entry . ~a~a~a" (list %eid) "~>" ((state-enclave.entry s) %eid))
     (fprintf port "\n  enclave.secure-lower . ~a~a~a" (list %eid) "~>" ((state-enclave.secure-lower s) %eid))
     (fprintf port "\n  enclave.secure-upper . ~a~a~a" (list %eid) "~>" ((state-enclave.secure-upper s) %eid))
     (fprintf port "\n  enclave.shared-lower . ~a~a~a" (list %eid) "~>" ((state-enclave.shared-lower s) %eid))
     (fprintf port "\n  enclave.shared-upper . ~a~a~a" (list %eid) "~>" ((state-enclave.shared-upper s) %eid))
     (fprintf port ")"))])


(define (make-havoc-regs)
  (define-symbolic*
    ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
    satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie
    (bitvector 64))
  (regs ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
    satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie))


(define (make-havoc-state)
  (define-symbolic* symbolic-enclave-mode boolean?)
  (define-symbolic* symbolic-current-enclave eid_t)
  (define-symbolic* symbolic-payload (~> i64 i8))
  (define-symbolic* symbolic-enclave.status (~> eid_t i64))
  (define-symbolic* symbolic-enclave.entry (~> eid_t i64))
  (define-symbolic* symbolic-enclave.secure-lower (~> eid_t i64))
  (define-symbolic* symbolic-enclave.secure-upper (~> eid_t i64))
  (define-symbolic* symbolic-enclave.shared-lower (~> eid_t i64))
  (define-symbolic* symbolic-enclave.shared-upper (~> eid_t i64))
  (state symbolic-enclave-mode
         symbolic-current-enclave
         symbolic-payload
         (make-havoc-regs)
         symbolic-enclave.status
         symbolic-enclave.entry
         symbolic-enclave.secure-lower
         symbolic-enclave.secure-upper
         symbolic-enclave.shared-lower
         symbolic-enclave.shared-upper))


(define-syntax-rule (make-state-updater name getter setter)
  (define (name state indices value)
    (setter state (update (getter state) indices value))))

(make-state-updater update-state-payload! state-payload set-state-payload!)
(make-state-updater update-state-enclave.status! state-enclave.status set-state-enclave.status!)
(make-state-updater update-state-enclave.entry! state-enclave.entry set-state-enclave.entry!)
(make-state-updater update-state-enclave.secure-lower! state-enclave.secure-lower set-state-enclave.secure-lower!)
(make-state-updater update-state-enclave.secure-upper! state-enclave.secure-upper set-state-enclave.secure-upper!)
(make-state-updater update-state-enclave.shared-lower! state-enclave.shared-lower set-state-enclave.shared-lower!)
(make-state-updater update-state-enclave.shared-upper! state-enclave.shared-upper set-state-enclave.shared-upper!)


(define (eid-valid? eid)
  (bvult eid (bv keystone:NR_ENCLAVES 64)))

(define (enclave-free? st eid)
  (&& (eid-valid? eid)
      (bveq ((state-enclave.status st) eid) (bv keystone:ENCLAVE_FREE 64))))

(define (offset-valid? offset)
  (bvult offset (bv keystone:MAX_PAYLOAD_SIZE 64)))


(define (region-valid? lower upper)
  (&& (bvaligned? lower 4)
      (bvaligned? upper 4)
      (bvult lower upper)
      (bvule upper (bv keystone:MAX_PAYLOAD_SIZE 64))))


(define (region-nonoverlap? s lower upper)
  (define-symbolic eid eid_t)
  (forall (list eid)
          (=> (eid-valid? eid)
              (! (&& (bvult lower ((state-enclave.secure-upper s) eid))
                     (bvugt upper ((state-enclave.secure-lower s) eid)))))))
