#lang rosette/safe

(require
  serval/lib/core
  serval/riscv/spec
  (only-in racket/base struct-copy make-parameter)
  (prefix-in certikos: "generated/monitors/certikos/verif/asm-offsets.rkt"))

(provide
  (all-defined-out)
  (all-from-out serval/riscv/spec))

(define nr-procs (make-parameter (bv certikos:NR_PROCS 64)))
(define nr-pages (make-parameter (bv certikos:NR_PAGES 64)))

(struct state (current-pid pages
               proc.state proc.next proc.owner proc.lower proc.upper
               page.owner
               proc.saved-regs
               regs)
  #:transparent #:mutable
  #:methods gen:equal+hash
  [(define (equal-proc s t equal?-recur)
     (define-symbolic q pindex poffset pid hartid (bitvector 64))
     (&& (equal?-recur (state-current-pid s) (state-current-pid t))
         (forall (var pindex poffset) (=> (&& (pindex-valid? pindex) (poffset-valid? poffset))
                                          (equal?-recur ((state-pages s) pindex poffset) ((state-pages t) pindex poffset))))
         (forall (var pid) (=> (pid-valid? pid)
                               (equal?-recur ((state-proc.state s) pid) ((state-proc.state t) pid))))
         (forall (var pid) (=> (pid-valid? pid)
                               (equal?-recur ((state-proc.next s) pid) ((state-proc.next t) pid))))
         (forall (var pid) (=> (pid-valid? pid)
                               (equal?-recur ((state-proc.owner s) pid) ((state-proc.owner t) pid))))
         (forall (var pid) (=> (pid-valid? pid)
                               (equal?-recur ((state-proc.lower s) pid) ((state-proc.lower t) pid))))
         (forall (var pid) (=> (pid-valid? pid)
                               (equal?-recur ((state-proc.upper s) pid) ((state-proc.upper t) pid))))
         (forall (var pid) (=> (pid-valid? pid) (equal?-recur ((state-proc.saved-regs s) pid)
                                                        ((state-proc.saved-regs t) pid))))
         (equal?-recur (state-regs s) (state-regs t))))
   (define (hash-proc s hash-recur) 1)
   (define (hash2-proc s hash2-recur) 2)]
  ; pretty-print function
  #:methods gen:custom-write
  [(define (write-proc s port mode)
     (define-symbolic %0 %1 %2 (bitvector 64))
     (fprintf port "(state")
     (fprintf port "\n  current-pid . ~a" (state-current-pid s))
     (fprintf port "\n  pages . ~a~a~a" (list %0 %1) "~>" ((state-pages s) %0 %1))
     (fprintf port "\n  proc.state . ~a~a~a" (list %0) "~>" ((state-proc.state s) %0))
     (fprintf port "\n  proc.owner . ~a~a~a" (list %0) "~>" ((state-proc.owner s) %0))
     (fprintf port "\n  proc.lower . ~a~a~a" (list %0) "~>" ((state-proc.lower s) %0))
     (fprintf port "\n  proc.upper . ~a~a~a" (list %0) "~>" ((state-proc.upper s) %0))
     (fprintf port ")"))])

(define-syntax-rule (make-state-updater name getter setter)
  (define (name state indices value)
    (setter state (update (getter state) indices value))))

(make-state-updater update-state-pages! state-pages set-state-pages!)
(make-state-updater update-state-proc.state! state-proc.state set-state-proc.state!)
(make-state-updater update-state-proc.next! state-proc.next set-state-proc.next!)
(make-state-updater update-state-proc.owner! state-proc.owner set-state-proc.owner!)
(make-state-updater update-state-proc.lower! state-proc.lower set-state-proc.lower!)
(make-state-updater update-state-proc.upper! state-proc.upper set-state-proc.upper!)
(make-state-updater update-state-proc.saved-regs! state-proc.saved-regs set-state-proc.saved-regs!)
(make-state-updater update-state-regs! state-regs set-state-regs!)
(make-state-updater update-state-page.owner! state-page.owner set-state-page.owner!)

(define (make-havoc-regs)
  (define-symbolic*
    ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
    satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie
    (bitvector 64))
  (regs ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
    satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie))


(define (make-havoc-state)
  (define-symbolic* symbolic-current-pid i64)
  (define-symbolic* symbolic-pages (~> i64 i64 i8))
  (define-symbolic* symbolic-proc.state (~> i64 i64))
  (define-symbolic* symbolic-proc.next (~> i64 i64))
  (define-symbolic* symbolic-proc.owner (~> i64 i64))
  (define-symbolic* symbolic-proc.lower (~> i64 i64))
  (define-symbolic* symbolic-proc.upper (~> i64 i64))
  (define-symbolic* symbolic-page.owner (~> i64 i64))

  (define symbolic-regs (make-havoc-regs))

  (define-symbolic*
    ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6
    satp scause scounteren sepc sscratch sstatus stvec stval mepc sip sie
    (~> (bitvector 64) (bitvector 64)))

  (define (symbolic-proc.saved-regs pid)
    (regs
      (ra pid) (sp pid) (gp pid) (tp pid) (t0 pid) (t1 pid)
      (t2 pid) (s0 pid) (s1 pid) (a0 pid) (a1 pid) (a2 pid) (a3 pid)
      (a4 pid) (a5 pid) (a6 pid) (a7 pid) (s2 pid) (s3 pid) (s4 pid)
      (s5 pid) (s6 pid) (s7 pid) (s8 pid) (s9 pid) (s10 pid) (s11 pid)
      (t3 pid) (t4 pid) (t5 pid) (t6 pid)
      (satp pid) (scause pid) (scounteren pid) (sepc pid)
      (sscratch pid) (sstatus pid) (stvec pid) (stval pid)
      (mepc pid) (sip pid) (sie pid)))

  (state symbolic-current-pid
         symbolic-pages
         symbolic-proc.state symbolic-proc.next symbolic-proc.owner
         symbolic-proc.lower symbolic-proc.upper symbolic-page.owner
         symbolic-proc.saved-regs
         symbolic-regs))

(define (state-copy s)
  (define current-pid (state-current-pid s))
  (define pages (state-pages s))
  (define proc.next (state-proc.next s))
  (define proc.state (state-proc.state s))
  (define proc.owner (state-proc.owner s))
  (define proc.lower (state-proc.lower s))
  (define proc.upper (state-proc.upper s))
  (define proc.saved-regs (state-proc.saved-regs s))
  (define old-regs (struct-copy regs (state-regs s)))
  (define page.owner (state-page.owner s))
  (state current-pid
         (lambda args (apply pages args))
         (lambda args (apply proc.state args))
         (lambda args (apply proc.next args))
         (lambda args (apply proc.owner args))
         (lambda args (apply proc.lower args))
         (lambda args (apply proc.upper args))
         (lambda args (apply page.owner args))
         (lambda args (apply proc.saved-regs args))
         old-regs))


(define (proc-parent? s parent child)
  (equal? ((state-proc.owner s) child) parent))

(define (proc-runnable? s pid)
  (equal? ((state-proc.state s) pid) (bv certikos:PROC_STATE_RUN 64)))

(define (pid-valid? pid)
  (&& (bvugt pid (bv 0 64))
      (bvult pid (nr-procs))))

(define (pindex-valid? pindex)
  (bvult pindex (nr-pages)))

(define (poffset-valid? poffset)
  (bvult poffset (bv 4096 64)))

(define (proc.state-run? state)
  (equal? state (bv certikos:PROC_STATE_RUN 64)))
