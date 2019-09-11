#lang racket

(require "../riscv32.rkt")
(require serval/lib/unittest)

(define tests
  (test-suite+
    "riscv32-alu32-x tests"
    (jit-test-case '(BPF_ALU64 BPF_MOV BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_ADD BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_SUB BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_AND BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_OR BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_XOR BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_LSH BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_RSH BPF_K))
    (jit-test-case '(BPF_ALU64 BPF_ARSH BPF_K))
    ; (jit-test-case '(BPF_ALU64 BPF_MUL BPF_K))
))

(module+ test
  (time (run-tests tests)))
