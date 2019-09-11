#lang rosette

(require
  (except-in rackunit fail)
  rackunit/text-ui
  rosette/lib/roseunit
  serval/riscv/objdump
  serval/riscv/shims
  serval/lib/core
  serval/lib/unittest
  serval/spec/refinement
  "spec.rkt"
  "state.rkt"
  "impl.rkt"
  (prefix-in keystone: "symbols.rkt")
  (prefix-in keystone: "generated/monitors/keystone.asm.rkt")
  "generated/monitors/keystone/verif/asm-offsets.rkt")

(define (find-symbol-start name)
  (define sym (find-symbol-by-name keystone:symbols name))
  (bug-on (equal? sym #f) #:msg (format "find-symbol-start: No such symbol ~e" name))
  (bv (car sym) (XLEN)))

(define (find-symbol-end name)
  (define sym (find-symbol-by-name keystone:symbols name))
  (bug-on (equal? sym #f) #:msg (format "find-symbol-end: No such symbol ~e" name))
  (bv (car (cdr sym)) (XLEN)))

(define (rep-invariant cpu)
  (define mregions (cpu-mregions cpu))

  (&& (bveq (csr-ref cpu 'mtvec) (find-symbol-start 'machine_trap_vector))
      (bveq (csr-ref cpu 'mscratch) (bvadd (find-symbol-start 'cpu_stack)
                                           (bv #x7f00 (XLEN))))
      (mregions-invariants mregions)))

(define (init-rep-invariant cpu)
  (csr-set! cpu 'mtvec (find-symbol-start 'machine_trap_vector))
  (csr-set! cpu 'mscratch (bvadd (find-symbol-start 'cpu_stack)
                                 (bv #x7f00 (XLEN)))))

(define (check-fresh-cpu)
  ; Check that the rep invariant holds on init-rep-invariant
  (define cpu0 (init-cpu keystone:symbols keystone:globals))
  (init-rep-invariant cpu0)
  (check-unsat? (verify (rep-invariant cpu0)) "init rep invariants do not hold")

  ; Check that init-rep-invariant does not overconstrain; the rep-invariant,
  ; i.e., executing init-rep-invariant; on a state satisfying the rep-invariant
  ; does not change anything.
  (define cpu1 (init-cpu keystone:symbols keystone:globals))
  (define cpu2 (init-cpu keystone:symbols keystone:globals))
  (with-asserts-only (begin
    (assert (cpu-equal? cpu1 cpu2))
    (assert (rep-invariant cpu1))
    (init-rep-invariant cpu2)
    (check-unsat? (verify (assert (cpu-equal? cpu1 cpu2))) "init-rep-invariant over-contrains")))
  (void))



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


(define (check-init-riscv)
  (define cpu (init-cpu keystone:symbols keystone:globals))
  (cpu-add-shim! cpu (find-symbol-start 'memset) memset-shim)
  (gpr-set! cpu 'a0 (bv CONFIG_BOOT_CPU (XLEN)))
  (define asserted
    (with-asserts-only (interpret-objdump-program cpu keystone:instructions)))
  (check-equal? asserted null)

  (check-unsat? (verify (assert (rep-invariant cpu))))

  (void))

(define (make-impl-func callno)
  (lambda (cpu . args)
    (interpret-objdump-program cpu keystone:instructions)))

(define (make-spec-func spec)
  (lambda (state . args)
    (define newmepc (bvadd (bv 4 64) (regs-mepc (state-regs state))))
    (when (! (eq? spec spec-sys_run_enclave))
      (set-state-regs! state (struct-copy regs (state-regs state) [mepc newmepc])))
    (apply spec state args)))

(define (verify-riscv-refinement spec-func callno [args null])
  (define cpu (init-cpu keystone:symbols keystone:globals))
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

(define keystone-riscv-tests
  (test-suite+ "keystone RISC-V tests"
    (test-case+ "init riscv check" (check-init-riscv))
    (test-case+ "riscv fresh cpu check" (check-fresh-cpu))

    (test-case+ "sys_create_enclave riscv refinement"
      (verify-riscv-refinement spec-sys_create_enclave __NR_create_enclave
        (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64))))
    (test-case+ "sys_destroy_enclave riscv refinement"
      (verify-riscv-refinement spec-sys_destroy_enclave __NR_destroy_enclave
        (list (make-bv64))))
    (test-case+ "sys_run_enclave riscv refinement"
      (verify-riscv-refinement spec-sys_run_enclave __NR_run_enclave
        (list (make-bv64))))
    (test-case+ "sys_exit_enclave riscv refinement"
      (verify-riscv-refinement spec-sys_exit_enclave __NR_exit_enclave
        null))
    (test-case+ "sys_resume_enclave riscv refinement"
      (verify-riscv-refinement spec-sys_resume_enclave __NR_resume_enclave
        (list (make-bv64))))

))

(module+ test
  (time (run-tests keystone-riscv-tests)))
