#lang rosette

; https://bugs.chromium.org/p/project-zero/issues/detail?id=1655

(require
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  serval/bpf
  serval/lib/unittest)

(define small_map 1)

(define insns (make-insns
  (BPF_LD_MAP_FD BPF_REG_ARG1 small_map)
  (BPF_MOV64_REG BPF_REG_ARG2 BPF_REG_FP)
  (BPF_ALU64_IMM BPF_ADD BPF_REG_ARG2 -4)
  (BPF_ST_MEM BPF_W BPF_REG_ARG2 0 9) ;oob index
  (BPF_EMIT_CALL BPF_FUNC_map_lookup_elem)

  ; compute r9 = laundered_frame_pointer
  (BPF_MOV64_REG BPF_REG_9 BPF_REG_FP)
  (BPF_ALU64_REG BPF_SUB BPF_REG_9 BPF_REG_0)

  ; store r9 into map
  (BPF_LD_MAP_FD BPF_REG_ARG1 small_map)
  (BPF_MOV64_REG BPF_REG_ARG2 BPF_REG_FP)
  (BPF_ALU64_IMM BPF_ADD BPF_REG_ARG2 -4)
  (BPF_ST_MEM BPF_W BPF_REG_ARG2 0 0) 
  (BPF_EMIT_CALL BPF_FUNC_map_lookup_elem)
  (BPF_JMP_IMM BPF_JNE BPF_REG_0 0 1) 
  (BPF_EXIT_INSN)
  (BPF_STX_MEM BPF_DW BPF_REG_0 BPF_REG_9 0) 

  (BPF_MOV64_IMM BPF_REG_0 0)
  (BPF_EXIT_INSN)))

(define (check-poc)
  (define fdtable (vector #f (make-array-map 8 1)))
  (define cpu (init-cpu #f fdtable))
  (check-exn exn:fail? (lambda () (with-asserts (interpret-program cpu insns))))
  (check-equal? current-pc-debug 16))

(define bpf-tests
  (test-suite+ "Tests for PoC (Project Zero 1686)"
    (test-case+ "kernel ptr leak via BPF: broken subtraction check" (check-poc))))

(module+ test
  (time (run-tests bpf-tests)))
