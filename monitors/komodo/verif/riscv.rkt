#lang rosette/safe

(require
  serval/riscv/objdump
  serval/riscv/shims
  serval/riscv/pmp
  serval/lib/core
  serval/spec/refcnt
  serval/lib/unittest
  serval/spec/refinement
  "spec.rkt"
  "state.rkt"
  "impl.rkt"
  "invariants.rkt"
  (only-in racket/base for values)
  (prefix-in komodo: "symbols.rkt")
  (prefix-in komodo: "generated/monitors/komodo.asm.rkt")
  "generated/monitors/komodo/verif/asm-offsets.rkt"
)

(define (find-symbol-start name)
  (define sym (find-symbol-by-name komodo:symbols name))
  (bug-on (equal? sym #f) #:msg (format "find-symbol-start: No such symbol ~e" name))
  (bv (car sym) (XLEN)))

(define (find-symbol-end name)
  (define sym (find-symbol-by-name komodo:symbols name))
  (bug-on (equal? sym #f) #:msg (format "find-symbol-end: No such symbol ~e" name))
  (bv (car (cdr sym)) (XLEN)))

(define (rep-invariant cpu)
  (define mregions (cpu-mregions cpu))

  (define pa-start (find-symbol-start '_start))
  (define pa-insecure-start (find-symbol-start '_payload_start))
  (define pa-insecure-end (bvadd pa-insecure-start (bv KOM_INSECURE_RESERVE 64)))
  (define pa-secure-start (find-symbol-start 'secure_pages))
  (define pa-secure-end (bvadd pa-secure-start (bv KOM_SECURE_RESERVE 64)))

  (define block-enclave-mode (find-block-by-name mregions 'enclave_mode))
  (define enclave-mode (mblock-iload block-enclave-mode null))
  (define enclave-mode-bool (! (bveq enclave-mode (bv 0 8))))

  (&& (bveq (csr-ref cpu 'mtvec) (find-symbol-start 'machine_trap_vector))
      (bveq (csr-ref cpu 'mscratch) (bvadd (find-symbol-start 'cpu_stack)
                                           (bv #x7f00 (XLEN))))

      (=> enclave-mode-bool
        (! (bvzero? (bvand (bv SR_TVM 64) (csr-ref cpu 'mstatus)))))

      (bveq (csr-ref cpu 'pmpcfg0)
        (concat
          (bv 0 8) ; 7
          (bv 0 8) ; 6
          (bvor (bv PMPCFG_A_TOR 8)
            (if enclave-mode-bool
              (bvor (bv PMPCFG_R 8) (bv PMPCFG_W 8) (bv PMPCFG_X 8))
              (bv 0 8))) ; 5
          (bv 0 8) ; 4
          (bvor (bv PMPCFG_A_TOR 8) (bv PMPCFG_R 8) (bv PMPCFG_W 8) (bv PMPCFG_X 8)) ; 3
          (bv 0 8) ; 2
          (bv 0 8) ; 1
          (bv 0 8))) ; 0

      (bveq (csr-ref cpu 'pmpcfg2) (bv 0 64))
      (bveq (csr-ref cpu 'pmpaddr0) (bv 0 64))
      (bveq (csr-ref cpu 'pmpaddr1) (bv 0 64))
      (bveq (csr-ref cpu 'pmpaddr2) (bvlshr pa-insecure-start (bv 2 (XLEN))))
      (bveq (csr-ref cpu 'pmpaddr3) (bvlshr pa-insecure-end (bv 2 (XLEN))))
      (bveq (csr-ref cpu 'pmpaddr4) (bvlshr pa-secure-start (bv 2 (XLEN))))
      (bveq (csr-ref cpu 'pmpaddr5) (bvlshr pa-secure-end (bv 2 (XLEN))))
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

      (mregions-invariants mregions)))

(define (init-rep-invariant cpu)
  (define mregions (cpu-mregions cpu))
  (define pa-start (find-symbol-start '_start))
  (define pa-insecure-start (find-symbol-start '_payload_start))
  (define pa-insecure-end (bvadd pa-insecure-start (bv KOM_INSECURE_RESERVE 64)))
  (define pa-secure-start (find-symbol-start 'secure_pages))
  (define pa-secure-end (bvadd pa-secure-start (bv KOM_SECURE_RESERVE 64)))

  (define block-enclave-mode (find-block-by-name mregions 'enclave_mode))
  (define enclave-mode (mblock-iload block-enclave-mode null))
  (define enclave-mode-bool (! (bveq enclave-mode (bv 0 8))))

  (csr-set! cpu 'mtvec (find-symbol-start 'machine_trap_vector))
  (csr-set! cpu 'mscratch (bvadd (find-symbol-start 'cpu_stack)
                                 (bv #x7f00 (XLEN))))
  (csr-set! cpu 'pmpcfg0
    (concat
      (bv 0 8) ; 7
      (bv 0 8) ; 6
      (bvor (bv PMPCFG_A_TOR 8)
        (if enclave-mode-bool
          (bvor (bv PMPCFG_R 8) (bv PMPCFG_W 8) (bv PMPCFG_X 8))
          (bv 0 8))) ; 5
      (bv 0 8) ; 4
      (bvor (bv PMPCFG_A_TOR 8) (bv PMPCFG_R 8) (bv PMPCFG_W 8) (bv PMPCFG_X 8)) ; 3
      (bv 0 8) ; 2
      (bv 0 8) ; 1
      (bv 0 8))) ; 0

  (csr-set! cpu 'pmpcfg2 (bv 0 64))
  (csr-set! cpu 'pmpaddr0 (bv 0 64))
  (csr-set! cpu 'pmpaddr1 (bv 0 64))
  (csr-set! cpu 'pmpaddr2 (bvlshr pa-insecure-start (bv 2 (XLEN))))
  (csr-set! cpu 'pmpaddr3 (bvlshr pa-insecure-end (bv 2 (XLEN))))
  (csr-set! cpu 'pmpaddr4 (bvlshr pa-secure-start (bv 2 (XLEN))))
  (csr-set! cpu 'pmpaddr5 (bvlshr pa-secure-end (bv 2 (XLEN))))
  (csr-set! cpu 'pmpaddr6 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr7 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr8 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr9 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr10 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr11 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr12 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr13 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr14 (bv 0 (XLEN)))
  (csr-set! cpu 'pmpaddr15 (bv 0 (XLEN))))


(define (check-fresh-cpu)
  ; Check that the rep invariant holds on init-rep-invariant
  (define cpu0 (init-cpu komodo:symbols komodo:globals))
  (init-rep-invariant cpu0)
  (check-unsat? (verify (rep-invariant cpu0)) "init rep invariants do not hold")

  (define (loweq s t)
    (&& (cpu-equal? s t)
        (bveq (mblock-iload (find-block-by-name (cpu-mregions s) 'enclave_mode) null)
              (mblock-iload (find-block-by-name (cpu-mregions t) 'enclave_mode) null))))

  ; Check that init-rep-invariant does not overconstrain; the rep-invariant,
  ; i.e., executing init-rep-invariant; on a state satisfying the rep-invariant
  ; does not change anything.
  (define cpu1 (init-cpu komodo:symbols komodo:globals))
  (define cpu2 (init-cpu komodo:symbols komodo:globals))
  (with-asserts-only (begin
    (assert (loweq cpu1 cpu2))
    (assert (rep-invariant cpu1))
    (init-rep-invariant cpu2)
    (check-unsat? (verify (assert (loweq cpu1 cpu2))) "init-rep-invariant over-contrains")))
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
  (define cpu (init-cpu komodo:symbols komodo:globals))
  (cpu-add-shim! cpu (find-symbol-start 'memset) memset-shim)
  (gpr-set! cpu 'a0 (bv CONFIG_BOOT_CPU (XLEN)))

  (check-asserts-only (interpret-objdump-program cpu komodo:instructions))

  (check-unsat? (verify (assert (rep-invariant cpu))))

  (define state (abs-function cpu))

  (set-state-page-refcnt! state (init-refcnt))
  (set-state-pgtable-present! state (lambda _ #f))
  (set-state-pgtable-secure! state (lambda _ #f))
  (set-state-pgtable-pn! state (lambda _ (bv 0 64)))
  (set-state-pgtable-perm! state (lambda _ (bv 0 64)))

  ; Check we didn't destory impl-visible state
  (check-unsat? (verify (assert (equal? state (abs-function cpu)))))
  ; Check that spec invariants hold on init state with some ghost state

  (check-unsat? (verify (assert (apply && (flatten (spec-invariants state))))))
  (check-unsat? (verify (assert (apply && (flatten (spec-refcnt-invariants state))))))
  (check-unsat? (verify (assert (apply && (flatten (spec-pgtable-invariants state))))))

  (void))

(define (check-pmp-ok)
  (define cpu (init-cpu komodo:symbols komodo:globals))
  (define mregions (cpu-mregions cpu))
  (init-rep-invariant cpu)
  (define pa-start (find-symbol-start '_start))
  (define pa-end (find-symbol-start '_end))
  (define block-enclave-mode (find-block-by-name mregions 'enclave_mode))
  (define enclave-mode (mblock-iload block-enclave-mode null))
  (define enclave-mode-bool (! (bveq enclave-mode (bv 0 8))))
  (define pa-insecure-start (find-symbol-start '_payload_start))
  (define pa-insecure-end (bvadd pa-insecure-start (bv KOM_INSECURE_RESERVE 64)))

  (define pre
    (&& (rep-invariant cpu)
        (! enclave-mode-bool)))

  (define-symbolic* ptr (bitvector 64))

  (define pmp-ok
    (let ([privs (pmp-privs cpu ptr (bv 1 64))])
      (|| (bveq (bvand (bv PMPCFG_R 8) privs) (bv PMPCFG_R 8))
          (bveq (bvand (bv PMPCFG_W 8) privs) (bv PMPCFG_W 8))
          (bveq (bvand (bv PMPCFG_X 8) privs) (bv PMPCFG_X 8)))))

  (check-unsat? (verify (assert (apply && (asserts)))))
  (check-unsat? (verify (assert
    (=> (&& pmp-ok pre)
      (&& (bvuge ptr pa-insecure-start)
          (bvult ptr pa-insecure-end))))))
)

(define (make-impl-func callno)
  (lambda (cpu . args)
    (interpret-objdump-program cpu komodo:instructions)))

(define (verify-riscv-refinement spec-func callno [args null])
  (define cpu (init-cpu komodo:symbols komodo:globals))
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
    #:spec spec-func
    #:abs abs-function
    #:ri rep-invariant
    args))

(define (verify-trap-handle)
  (define cpu (init-cpu komodo:symbols komodo:globals))
  (init-rep-invariant cpu)
  (cpu-add-shim! cpu (find-symbol-start 'memset) memset-shim)
  (set-cpu-pc! cpu (csr-ref cpu 'mtvec))
  (define cause (csr-ref cpu 'mcause))

  (cond
    [(bveq cause (bv EXC_ECALL_S 64)) (void)]
    [else
      (verify-refinement
        #:implstate cpu
        #:impl (make-impl-func #f)
        #:specstate (make-havoc-state)
        #:spec spec-kom_handle_trap
        #:abs abs-function
        #:ri rep-invariant
        (list (csr-ref cpu 'mcause)))])

  (clear-asserts!))

(define (verify-ecall-refinement)
  (define cpu (init-cpu komodo:symbols komodo:globals))
  (init-rep-invariant cpu)
  (cpu-add-shim! cpu (find-symbol-start 'memset) memset-shim)
  (csr-set! cpu 'mcause (bv EXC_ECALL_S 64))
  (set-cpu-pc! cpu (csr-ref cpu 'mtvec))

  (split-cases
    (gpr-ref cpu 'a7)
    (list (bv KOM_SMC_QUERY 64)
          (bv KOM_SMC_GETPHYSPAGES 64)
          (bv KOM_SMC_INIT_ADDRSPACE 64)
          (bv KOM_SMC_INIT_DISPATCHER 64)
          (bv KOM_SMC_INIT_L2PTABLE 64)
          (bv KOM_SMC_INIT_L3PTABLE 64)
          (bv KOM_SMC_MAP_SECURE 64)
          (bv KOM_SMC_MAP_INSECURE 64)
          (bv KOM_SMC_REMOVE 64)
          (bv KOM_SMC_FINALISE 64)
          (bv KOM_SMC_STOP 64)
          (bv KOM_SMC_ENTER 64)
          (bv KOM_SMC_RESUME 64)
          (bv KOM_SVC_EXIT 64))
    (lambda (v)
      (gpr-set! cpu 'a7 v)

      (define (check name spec args)
        (test-case+ (format "komodo riscv ~a" name)
          (check-equal? (asserts) null)
          (for ([reg '(a0 a1 a2 a3 a4 a5 a6)] [arg args])
            (gpr-set! cpu reg arg))
          (verify-refinement
            #:implstate cpu
            #:impl (make-impl-func #f)
            #:specstate (make-havoc-state)
            #:spec spec
            #:abs abs-function
            #:ri rep-invariant
            args)))

      (cond
        [(equal? v (bv KOM_SMC_QUERY 64))
          (check "kom_smc_query" (make-smc-spec spec-kom_smc_query) null)]
        [(equal? v (bv KOM_SMC_GETPHYSPAGES 64))
          (check "kom_smc_get_phys_pages" (make-smc-spec spec-kom_smc_get_phys_pages) null)]

        [(equal? v (bv KOM_SMC_INIT_ADDRSPACE 64))
          (check "kom_smc_init_addrspace" (make-smc-spec spec-kom_smc_init_addrspace) (list (make-bv64) (make-bv64)))]

        [(equal? v (bv KOM_SMC_INIT_DISPATCHER 64))
          (check "kom_smc_init_dispatcher" (make-smc-spec spec-kom_smc_init_dispatcher) (list (make-bv64) (make-bv64) (make-bv64)))]

        [(equal? v (bv KOM_SMC_INIT_L2PTABLE 64))
          (check "kom_smc_init_l2ptable" (make-smc-spec spec-kom_smc_init_l2ptable) (list (make-bv64) (make-bv64) (make-bv64)))]

        [(equal? v (bv KOM_SMC_INIT_L3PTABLE 64))
          (check "kom_smc_init_l3ptable" (make-smc-spec spec-kom_smc_init_l3ptable) (list (make-bv64) (make-bv64) (make-bv64)))]

        [(equal? v (bv KOM_SMC_MAP_SECURE 64))
          (check "kom_smc_map_secure" (make-smc-spec spec-kom_smc_map_secure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64) (make-bv64)))]

        [(equal? v (bv KOM_SMC_MAP_INSECURE 64))
          (check "kom_smc_map_insecure" (make-smc-spec spec-kom_smc_map_insecure) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64)))]

        [(equal? v (bv KOM_SMC_REMOVE 64))
          (check "kom_smc_remove" (make-smc-spec spec-kom_smc_remove) (list (make-bv64)))]

        [(equal? v (bv KOM_SMC_FINALISE 64))
          (check "kom_smc_finalise" (make-smc-spec spec-kom_smc_finalise) (list (make-bv64)))]

        [(equal? v (bv KOM_SMC_STOP 64))
          (check "kom_smc_stop" (make-smc-spec spec-kom_smc_stop) (list (make-bv64)))]

        [(equal? v (bv KOM_SMC_ENTER 64))
          (check "kom_smc_enter" (make-smc-spec spec-kom_smc_enter) (list (make-bv64) (make-bv64) (make-bv64) (make-bv64)))]

        [(equal? v (bv KOM_SMC_RESUME 64))
          (check "kom_smc_resume" (make-smc-spec spec-kom_smc_resume) (list (make-bv64)))]

        [(equal? v (bv KOM_SVC_EXIT 64))
          (check "kom_svc_exit" spec-kom_svc_exit (list (make-bv64)))]

        [else (check "kom_enosys" spec-kom_enosys null)])
      (void))))


(define komodo-riscv-tests
  (test-suite+ "komodo RISC-V tests"
    (test-case+ "trap handle" (verify-trap-handle))
    (test-case+ "init riscv check" (check-init-riscv))
    (test-case+ "riscv fresh cpu check" (check-fresh-cpu))
    (test-case+ "check pmp ok" (check-pmp-ok))

    (verify-ecall-refinement)
))

(module+ test
  (time (run-tests komodo-riscv-tests)))
