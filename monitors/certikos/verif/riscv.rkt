#lang rosette/safe

(require serval/riscv/objdump
  serval/riscv/shims
  serval/lib/core
  serval/lib/unittest
  serval/spec/refinement
  serval/riscv/pmp
  "spec.rkt"
  "impl.rkt"
  "invariants.rkt"
  "state.rkt"
  (prefix-in certikos: "generated/monitors/certikos.map.rkt")
  (prefix-in certikos: "generated/monitors/certikos.globals.rkt")
  (prefix-in certikos: "generated/monitors/certikos.asm.rkt")
  "generated/monitors/certikos/verif/asm-offsets.rkt"
  (only-in racket/base struct-copy for)
)


(provide (all-defined-out))

(define (find-symbol-start name)
  (define sym (find-symbol-by-name certikos:symbols name))
  (bug-on (equal? sym #f) #:msg (format "find-symbol-start: No such symbol ~e" name))
  (bv (car sym) (XLEN)))

(define (find-symbol-end name)
  (define sym (find-symbol-by-name certikos:symbols name))
  (bug-on (equal? sym #f) #:msg (format "find-symbol-end: No such symbol ~e" name))
  (bv (car (cdr sym)) (XLEN)))

(define init-pmpcfg0
  (concat
    (bv 0 8)
    (bv 0 8)
    (bv 0 8)
    (bv 0 8)
    (bvor (bv PMPCFG_A_TOR 8) (bv PMPCFG_R 8) (bv PMPCFG_X 8))
    (bv 0 8)
    (bvor (bv PMPCFG_A_TOR 8) (bv PMPCFG_R 8) (bv PMPCFG_W 8) (bv PMPCFG_X 8))
    (bv 0 8)))

(define init-medeleg
  (bvor (bv EDEL_BREAKPOINT 64) (bv EDEL_ECALL_U 64)
    (bv EDEL_INST_MISALIGNED 64) (bv EDEL_INST_PAGE_FAULT 64)
    (bv EDEL_LOAD_MISALIGNED 64) (bv EDEL_LOAD_PAGE_FAULT 64)
    (bv EDEL_STORE_MISALIGNED 64) (bv EDEL_STORE_PAGE_FAULT 64)))

(define (rep-invariant cpu)
  (define mregions (cpu-mregions cpu))
  (define block-current-pid (find-block-by-name mregions 'current_pid))
  (define block-procs (find-block-by-name mregions 'procs))
  (define current-pid (mblock-iload block-current-pid null))
  (define current-lower (mblock-iload block-procs (list current-pid 'lower)))
  (define current-upper (mblock-iload block-procs (list current-pid 'upper)))
  (define pages-start (find-symbol-start 'pages))

  (&& (bveq (csr-ref cpu 'mtvec) (find-symbol-start 'machine_trap_vector))
      (bveq (csr-ref cpu 'mscratch) (bvadd (find-symbol-start 'cpu_stack)
                                           (bv #x7f00 (XLEN))))
      (bveq (csr-ref cpu 'mcounteren) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'mideleg) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'medeleg) init-medeleg)

      (bveq (csr-ref cpu 'pmpcfg0) init-pmpcfg0)
      (bveq (csr-ref cpu 'pmpcfg2) (bv 0 (XLEN)))

      (bveq (csr-ref cpu 'pmpaddr0)
        (bvlshr (bvadd pages-start (bvshl current-lower (bv 12 64))) (bv 2 64)))
      (bveq (csr-ref cpu 'pmpaddr1)
        (bvlshr (bvadd pages-start (bvshl current-upper (bv 12 64))) (bv 2 64)))
      (bveq (csr-ref cpu 'pmpaddr2) (bvlshr (find-symbol-start '_payload_start) (bv 2 (XLEN))))
      (bveq (csr-ref cpu 'pmpaddr3) (bvlshr (find-symbol-start '_payload_end) (bv 2 (XLEN))))
      (bveq (csr-ref cpu 'pmpaddr4) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr5) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr6) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr7) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr8) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr9) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr10) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr11) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr12) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr13) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr14) (bv 0 (XLEN)))
      (bveq (csr-ref cpu 'pmpaddr15) (bv 0 (XLEN)))
      (mregions-invariants (cpu-mregions cpu))))

; Sanity checks on PMP code
(define (check-pmp)
  (define cpu (init-cpu certikos:symbols certikos:globals))
  (init-rep-invariant cpu)

  (define mregions (cpu-mregions cpu))
  (define block-current-pid (find-block-by-name mregions 'current_pid))
  (define block-procs (find-block-by-name mregions 'procs))
  (define current-pid (mblock-iload block-current-pid null))
  (define current-lower (mblock-iload block-procs (list current-pid 'lower)))
  (define current-upper (mblock-iload block-procs (list current-pid 'upper)))
  (define pages-start (find-symbol-start 'pages))
  (define pages-end (find-symbol-end 'pages))
  (define payload-start (find-symbol-start '_payload_start))
  (define payload-end (find-symbol-start '_payload_end))

  (define-symbolic* ptr (bitvector 64))

  ; Check a ptr that points outside of any PMP region
  (define pre (&& (rep-invariant cpu)
                  (|| (bvult ptr pages-start) (bvugt ptr pages-end))
                  (|| (bvult ptr payload-start) (bvugt ptr payload-end))))
  (check-sat? (solve (assert pre)))
  (check-equal? (asserts) null)
  (check-unsat? (verify (assert
    (=> pre (bveq (pmp-privs cpu ptr (bv 4 64)) (bv 0 8))))))

  ; Check a valid ptr
  (define-symbolic* pgindex offset (bitvector 64))
  (define ptr2 (bvadd pages-start (bvshl pgindex (bv 12 64)) offset))

  (define pre2 (&& (rep-invariant cpu)
                  (bvult offset (bv 4096 64)) ; offset in bounds
                  (bveq (bvurem offset (bv 8 64)) (bv 0 64)) ; access aligned
                  (bvuge pgindex current-lower) ; pgindex above lower
                  (bvult pgindex current-upper) ; pgindex below upper
                  ))
  (check-sat? (solve (assert pre2)))
  (check-equal? (asserts) null)
  (check-unsat? (verify (assert
    (=> pre2 (bveq (pmp-privs cpu ptr2 (bv 8 64)) (bv PMPCFG_RWX 8)))))))

; Return a fresh CPU of the state at trap entry.
; We prove that this is consistent with the rep-invariant.
(define (init-rep-invariant cpu)
  (csr-set! cpu 'mtvec (find-symbol-start 'machine_trap_vector))
  (csr-set! cpu 'pmpcfg0 init-pmpcfg0)
  (csr-set! cpu 'pmpcfg2 (bv 0 (XLEN)))

  (csr-set! cpu 'pmpaddr2 (bvlshr (find-symbol-start '_payload_start) (bv 2 (XLEN))))
  (csr-set! cpu 'pmpaddr3 (bvlshr (find-symbol-start '_payload_end) (bv 2 (XLEN))))
  (csr-set! cpu 'pmpaddr4 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr5 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr6 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr7 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr8 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr9 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr10 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr11 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr12 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr13 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr14 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr15 (bv 0 (XLEN)))
  (csr-set! cpu 'mscratch (bvadd (find-symbol-start 'cpu_stack)
                                 (bv #x7f00 (XLEN)))))

(define (check-fresh-cpu)

  ; Check that the rep invariant holds on init-rep-invariant
  (define cpu0 (init-cpu certikos:symbols certikos:globals))
  (init-rep-invariant cpu0)
  (check-unsat? (verify (rep-invariant cpu0)) "init rep invariants do not hold")

  ; Check that init-rep-invariant does not overconstrain; the rep-invariant,
  ; i.e., executing init-rep-invariant; on a state satisfying the rep-invariant
  ; does not change anything.
  (define cpu1 (init-cpu certikos:symbols certikos:globals))
  (define cpu2 (init-cpu certikos:symbols certikos:globals))
  (with-asserts-only (begin
    (assert (cpu-equal? cpu1 cpu2))
    (assert (rep-invariant cpu1))
    (init-rep-invariant cpu2)
    (check-unsat? (verify (assert (cpu-equal? cpu1 cpu2))) "init-rep-invariant over-contrains")))
  (void))


(define (check-init-riscv)
  (define cpu (init-cpu certikos:symbols certikos:globals))
  (cpu-add-shim! cpu (find-symbol-start 'memset) memset-shim)
  (gpr-set! cpu 'a0 (bv CONFIG_BOOT_CPU (XLEN)))
  (define asserted
    (with-asserts-only (interpret-objdump-program cpu certikos:instructions)))
  (check-equal? asserted null)

  (check-unsat? (verify (assert (rep-invariant cpu))))

  ; Initialize spec state and set ownership of every page to IDLE
  (define state (abs-function cpu))
  (set-state-page.owner! state (const (bv 1 64)))

  ; Check we didn't destory impl-visible state
  (check-unsat? (verify (assert (equal? state (abs-function cpu)))))
  ; Check that spec invariants hold on init state with some ghost state
  (check-unsat? (verify (assert (spec-invariants state))))

  (void))

(define (make-impl-func callno)
  (lambda (cpu . args)
    (interpret-objdump-program cpu certikos:instructions)))

(define (abs-function cpu)
  (define state (mregions-abstract (cpu-mregions cpu)))
  (set-state-regs! state
    (regs (gpr-ref cpu 'ra) (gpr-ref cpu 'sp) (gpr-ref cpu 'gp) (gpr-ref cpu 'tp) (gpr-ref cpu 't0)
          (gpr-ref cpu 't1) (gpr-ref cpu 't2) (gpr-ref cpu 's0) (gpr-ref cpu 's1) (gpr-ref cpu 'a0)
          (gpr-ref cpu 'a1) (gpr-ref cpu 'a2) (gpr-ref cpu 'a3) (gpr-ref cpu 'a4) (gpr-ref cpu 'a5)
          (gpr-ref cpu 'a6) (gpr-ref cpu 'a7) (gpr-ref cpu 's2) (gpr-ref cpu 's3) (gpr-ref cpu 's4)
          (gpr-ref cpu 's5) (gpr-ref cpu 's6) (gpr-ref cpu 's7) (gpr-ref cpu 's8) (gpr-ref cpu 's9)
          (gpr-ref cpu 's10) (gpr-ref cpu 's11) (gpr-ref cpu 't3) (gpr-ref cpu 't4) (gpr-ref cpu 't5)
          (gpr-ref cpu 't6)
          (csr-ref cpu 'satp) (csr-ref cpu 'scause) (csr-ref cpu 'scounteren) (csr-ref cpu 'sepc)
          (csr-ref cpu 'sscratch) (csr-ref cpu 'sstatus) (csr-ref cpu 'stvec) (csr-ref cpu 'stval)
          (csr-ref cpu 'mepc) (csr-ref cpu 'sip) (csr-ref cpu 'sie)))
  state)

(define (make-spec-func spec)
  (lambda (state . args)
    (define newmepc (bvadd (bv 4 64) (regs-mepc (state-regs state))))
    (set-state-regs! state (struct-copy regs (state-regs state) [mepc newmepc]))
    (apply spec state args)))

(define (check-read-refinement ptr)
  (define cpu (init-cpu certikos:symbols certikos:globals))
  (init-rep-invariant cpu)
  (define pages-start (find-symbol-start 'pages))
  (define pages-end (find-symbol-end 'pages))
  (define block-pages (find-block-by-name (cpu-mregions cpu) 'pages))
  (define payload-start (find-symbol-start '_payload_start))
  (define payload-end (find-symbol-start '_payload_end))

  (define pgindex (bvlshr (bvsub ptr pages-start) (bv 12 64)))
  (define offset (bvurem (bvsub ptr pages-start) (bv 4096 64)))

  (define state (make-havoc-state))

  (define ptr2 (bvadd (bvadd pages-start (bvshl pgindex (bv 12 64))) offset))
  (check-unsat? (verify (assert (bveq ptr ptr2))))

  (gpr-set! cpu 'a0 ptr2)

  (define pre
   (&& (rep-invariant cpu)
       (equal? state (abs-function cpu))))


  ; RISC-V lets pages be executable but not readable. For our purposes there is essentially no
  ; difference between read and execute, so a "read" will succeed if either the X-bit or R-bit is set.
  (define pmp-ok
    (let ([privs (pmp-privs cpu ptr (bv 1 64))])
      (|| (bveq (bvand (bv PMPCFG_R 8) privs) (bv PMPCFG_R 8))
          (bveq (bvand (bv PMPCFG_X 8) privs) (bv PMPCFG_X 8)))))

  (check-equal? (asserts) null)
  (check-sat? (solve (assert pmp-ok)))
  (check-unsat? (verify (assert
    (=> (&& pmp-ok (rep-invariant cpu))
        (|| (&& (bvuge ptr payload-start) (bvult ptr payload-end))
            (&& (bvuge ptr pages-start) (bvult ptr pages-end)))))))

  (define ptr-in-pages (&& (bvuge ptr pages-start) (bvult ptr pages-end)))

  (define asserted
    (with-asserts-only
      (when (&& pmp-ok ptr-in-pages)
        (define i (instr 'lb 'a0 'a0 #f (bv 0 12) 4))
        (interpret-instr cpu i))))
  (check-unsat? (verify (assert (=> pre (apply && asserted)))))

  (spec-read state pgindex offset)

  (check-equal? (asserts) null)
  (check-unsat? (verify (assert (=> pre (rep-invariant cpu)))))
  (check-unsat? (verify (assert (=> pre (equal? state (abs-function cpu)))))))

(define (check-write-refinement ptr value)
  (define cpu (init-cpu certikos:symbols certikos:globals))
  (init-rep-invariant cpu)
  (define pages-start (find-symbol-start 'pages))
  (define block-pages (find-block-by-name (cpu-mregions cpu) 'pages))

  (define pgindex (bvlshr (bvsub ptr pages-start) (bv 12 64)))
  (define offset (bvurem (bvsub ptr pages-start) (bv 4096 64)))

  (define state (make-havoc-state))

  (define ptr2 (bvadd (bvadd pages-start (bvshl pgindex (bv 12 64))) offset))
  (check-unsat? (verify (assert (bveq ptr ptr2))))

  (check-equal? (asserts) null)

  (gpr-set! cpu 'a0 ptr2)
  (gpr-set! cpu 'a1 (zero-extend value (bitvector 64)))

  (define pre
   (&& (rep-invariant cpu)
       (equal? state (abs-function cpu))))

  (check-sat? (solve (assert pre)))

  (define pmp-ok (bveq
         (bvand (bv PMPCFG_W 8) (pmp-privs cpu ptr (bv 1 64)))
         (bv PMPCFG_W 8)))

  (define asserted
    (with-asserts-only
      (when pmp-ok
        (define i (instr 'sb #f 'a0 'a1 (bv 0 12) 4))
        (interpret-instr cpu i))))
  (check-unsat? (verify (assert (=> pre (apply && asserted)))))

  (spec-write state pgindex offset value)

  (check-equal? (asserts) null)
  (check-unsat? (verify (assert (=> pre (rep-invariant cpu)))))
  (check-unsat? (verify (assert (=> pre (equal? state (abs-function cpu)))))))


(define (check-ecall-refinement)
  (define cpu (init-cpu certikos:symbols certikos:globals))
  (init-rep-invariant cpu)
  (cpu-add-shim! cpu (find-symbol-start 'memset) memset-shim)
  (csr-set! cpu 'mcause (bv EXC_ECALL_S 64))
  (set-cpu-pc! cpu (csr-ref cpu 'mtvec))

  (split-cases
    (gpr-ref cpu 'a7)
    (list (bv __NR_spawn 64)
          (bv __NR_get_quota 64)
          (bv __NR_yield 64)
          (bv __NR_getpid 64))
    (lambda (v)
      (gpr-set! cpu 'a7 v)
      (verify-refinement
        #:implstate cpu
        #:impl (make-impl-func #f)
        #:specstate (make-havoc-state)
        #:spec spec-step-trap
        #:abs abs-function
        #:ri rep-invariant))))


(define (verify-riscv-refinement spec-func callno [args null])
  (define cpu (init-cpu certikos:symbols certikos:globals))
  (init-rep-invariant cpu)
  (cpu-add-shim! cpu (find-symbol-start 'memset) memset-shim)

  ; Initialize CPU state with the arguments
  (for ([reg '(a0 a1 a2 a3 a4 a5 a6)] [arg args])
    (gpr-set! cpu reg arg))
  (gpr-set! cpu 'a7 (bv callno (XLEN)))
  (csr-set! cpu 'mcause (bv EXC_ECALL_S 64))
  (set-cpu-pc! cpu (csr-ref cpu 'mtvec))

  (verify-refinement
    #:implstate cpu
    #:impl (make-impl-func callno)
    #:specstate (make-havoc-state)
    #:spec (make-spec-func spec-func)
    #:abs abs-function
    #:ri rep-invariant
    args))

(define certikos-riscv-tests
  (test-suite+ "certikos RISC-V tests"
    (test-case+ "syscall refinement" (check-ecall-refinement))
    (test-case+ "read refinement" (check-read-refinement (make-bv64)))
    (test-case+ "write refinement" (check-write-refinement (make-bv64) (make-bv8)))
    (test-case+ "PMP sanity" (check-pmp))
    (test-case+ "RISC-V init test" (check-init-riscv))
    (test-case+ "check-fresh-cpu"
      (check-fresh-cpu))
    ; (test-case+ "check sys_getpid"
    ;   (verify-riscv-refinement spec-sys_getpid __NR_getpid))
    ; (test-case+ "check sys_getquota"
    ;   (verify-riscv-refinement spec-sys_get_quota __NR_get_quota))
    ; (test-case+ "check sys_spawn"
    ;   (verify-riscv-refinement spec-sys_spawn __NR_spawn (list (make-bv64) (make-bv64) (make-bv64))))
    ; (test-case+ "check sys_yield"
    ;   (verify-riscv-refinement spec-sys_yield __NR_yield))

))

(module+ test
  (time (run-tests certikos-riscv-tests)))
