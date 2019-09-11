#lang rosette

; https://bugs.chromium.org/p/project-zero/issues/detail?id=1686
; CVE-2018-18445
;
; The checker mishandles 32-bit BPF_RSH by performing a 64-bit shift
; and truncating the result to 32-bit.  A correct way is to perform a
; 32-bit shift.  Using this bug, one can trick the checker to believe
; that ((2^32) >>32 31) to be 2 (which should have been 0) and fail
; to catch buffer overflows.

(require
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  serval/bpf
  serval/lib/unittest)

(define small_map 1)

(define insns (make-insns
  (BPF_MOV64_IMM BPF_REG_8 2)
  (BPF_ALU64_IMM BPF_LSH BPF_REG_8 31)
  ; r8 is 0 (or 2 if buggy)
  (BPF_ALU32_IMM BPF_RSH BPF_REG_8 31)
  ; r8 is -2 (or 0 if buggy)
  (BPF_ALU32_IMM BPF_SUB BPF_REG_8 2)

  (BPF_LD_MAP_FD BPF_REG_ARG1 small_map)
  (BPF_MOV64_REG BPF_REG_ARG2 BPF_REG_FP)
  (BPF_ALU64_IMM BPF_ADD BPF_REG_ARG2 -4)
  (BPF_ST_MEM BPF_W BPF_REG_ARG2 0 0)
  (BPF_EMIT_CALL BPF_FUNC_map_lookup_elem)
  (BPF_JMP_IMM BPF_JNE BPF_REG_0 0 1)
  (BPF_EXIT_INSN)
  ; r0 points to offset -2 to an array element (or the element if buggy)
  (BPF_ALU64_REG BPF_ADD BPF_REG_0 BPF_REG_8)
  ; buffer overflow (or passed if buggy)
  (BPF_STX_MEM BPF_DW BPF_REG_0 BPF_REG_8 0)

  (BPF_MOV64_IMM BPF_REG_0 0)
  (BPF_EXIT_INSN)))

(define (check-poc)
  (define fdtable (vector #f (make-array-map 8 1)))
  (define cpu (init-cpu #f fdtable))
  (check-exn exn:fail? (lambda () (with-asserts (interpret-program cpu insns))))
  (check-equal? current-pc-debug 13))

(define bpf-tests
  (test-suite+ "Tests for PoC (Project Zero 1686)"
    (test-case+ "CVE-2018-18445" (check-poc))))

(module+ test
  (time (run-tests bpf-tests)))
