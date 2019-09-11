#lang rosette/safe

(require
  serval/lib/core
  serval/lib/unittest
  "state.rkt"
  (only-in racket/base struct-copy)
  (prefix-in riscv: serval/riscv/objdump)
  (prefix-in certikos: "generated/monitors/certikos.map.rkt")
  (prefix-in certikos: "generated/monitors/certikos/verif/asm-offsets.rkt")
)

(provide (all-defined-out))

(define (spec-return s val)
  (set-state-regs! s (struct-copy regs (state-regs s) [a0 val])))

(define (spec-sys_get_quota s)
  (define pid (state-current-pid s))
  (spec-return s
    (bvsub ((state-proc.upper s) pid)
           ((state-proc.lower s) pid))))

(define (spec-sys_getpid s)
  (spec-return s (state-current-pid s)))

(define (spec-do_yield s)
  (define current-pid (state-current-pid s))
  (define next-pid ((state-proc.next s) current-pid))
  (set-state-current-pid! s next-pid)
  (spec-return s (bv 0 64)))

(define (spec-sys_yield s)

  (define current-pid (state-current-pid s))
  (define old-regs (struct-copy regs (state-regs s)))
  (define old-saved-regs (state-proc.saved-regs s))

  (set-state-proc.saved-regs! s
    (lambda (pid)
      (if (equal? pid current-pid)
          old-regs
          (old-saved-regs pid))))

  (spec-do_yield s)

  (define new-pid (state-current-pid s))
  (set-state-regs! s ((state-proc.saved-regs s) new-pid)))

(define (spec-sys_spawn s fileid quota pid)
  (define parent-pid (state-current-pid s))
  (define parent-lower ((state-proc.lower s) parent-pid))
  (define parent-upper ((state-proc.upper s) parent-pid))

  (cond
    [(! (bvule quota (bvsub parent-upper parent-lower)))
      (spec-return s (bv (- certikos:EINVAL) 64))]
    [(! (pid-valid? pid))
      (spec-return s (bv (- certikos:EINVAL) 64))]
    [(! (equal? ((state-proc.owner s) pid) parent-pid))
      (spec-return s (bv (- certikos:EINVAL) 64))]
    [(! (equal? ((state-proc.state s) pid) (bv certikos:PROC_STATE_FREE 64)))
      (spec-return s (bv (- certikos:EINVAL) 64))]
    [else
      (define child-lower (bvsub parent-upper quota))
      (update-state-proc.state! s (list pid) (bv certikos:PROC_STATE_RUN 64))
      (update-state-proc.lower! s (list pid) child-lower)
      (update-state-proc.upper! s (list pid) parent-upper)
      (update-state-proc.upper! s (list parent-pid) child-lower)

      (define pages (bv (car (find-symbol-by-name certikos:symbols 'pages)) 64))
      (define payload-start (bv (car (find-symbol-by-name certikos:symbols '_payload_start)) 64))

      (define new-regs (struct-copy regs (zero-regs)
        [a0 fileid]
        [a1 (bvadd pages (bvshl child-lower (bv 12 64)))]
        [mepc payload-start]))
      (update-state-proc.saved-regs! s (list pid) new-regs)

      ; child memory region
      (define (pindex-child? pindex)
        (&& (bvuge pindex child-lower) (bvult pindex parent-upper)))

      ; memset pages for the child process
      (update-state-pages! s (list pindex-child? poffset-valid?) (bv 0 8))

      (update-state-proc.next! s (list pid) ((state-proc.next s) parent-pid))
      (update-state-proc.next! s (list parent-pid) pid)

      ; update page ownership
      (update-state-page.owner! s pindex-child? pid)

      (spec-return s (bv 0 64))]))

(define (spec-read s page off)
  (define current-pid (state-current-pid s))
  (define current-lower ((state-proc.lower s) current-pid))
  (define current-upper ((state-proc.upper s) current-pid))
  (when (&& (bvuge page current-lower)
            (bvult page current-upper)
            (poffset-valid? off))
    (define value (sign-extend ((state-pages s) page off) (bitvector 64)))
    (set-state-regs! s (struct-copy regs (state-regs s) [a0 value]))))

(define (spec-write s page off value)
  (define current-pid (state-current-pid s))
  (define current-lower ((state-proc.lower s) current-pid))
  (define current-upper ((state-proc.upper s) current-pid))
  (when (&& (bvuge page current-lower)
            (bvult page current-upper)
            (poffset-valid? off))
    (update-state-pages! s (list page off) value)))

(define (spec-write-regs s regs)
  (set-state-regs! s regs))


(define (spec-step-trap s)
  (define current (state-current-pid s))
  (define callno (regs-a7 (state-regs s)))

  (define arg0 (regs-a0 (state-regs s)))
  (define arg1 (regs-a1 (state-regs s)))
  (define arg2 (regs-a2 (state-regs s)))
  (define arg3 (regs-a3 (state-regs s)))

  (define newmepc (bvadd (bv 4 64) (regs-mepc (state-regs s))))
  (set-state-regs! s (struct-copy regs (state-regs s) [mepc newmepc]))

  (cond
    [(bveq callno (bv certikos:__NR_spawn 64)) (spec-sys_spawn s arg0 arg1 arg2)]
    [(bveq callno (bv certikos:__NR_yield 64)) (spec-sys_yield s)]
    [(bveq callno (bv certikos:__NR_getpid 64)) (spec-sys_getpid s)]
    [(bveq callno (bv certikos:__NR_get_quota 64)) (spec-sys_get_quota s)]
    [else (spec-return s (bv (- certikos:ENOSYS) 64))]))

(define (make-choice)
  (define-symbolic* b0 b1 b2 boolean?)
  (if b0
    (list 'syscall)
    (if b1
      (list 'write (make-bv64) (make-bv64) (make-bv8))
      (if b2
        (list 'read (make-bv64) (make-bv64))
        (list 'havoc-regs (make-havoc-regs))))))

(define (spec-step s choice)
  (define current (state-current-pid s))
  (define action (car choice))
  (cond
    [(equal? action 'syscall) (spec-step-trap s)]
    [(equal? action 'write) (apply spec-write s (cdr choice))]
    [(equal? action 'read) (apply spec-read s (cdr choice))]
    [(equal? action 'havoc-regs) (apply spec-write-regs s (cdr choice))]))
