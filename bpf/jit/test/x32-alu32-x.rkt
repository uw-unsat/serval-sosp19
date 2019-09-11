
#lang racket

(require "../x32.rkt")
(require serval/lib/unittest)

(define tests
  (test-suite+
    "x32-alu32-x tests"
    (jit-test-case '(BPF_ALU BPF_MOV BPF_X))
    (jit-test-case '(BPF_ALU BPF_ADD BPF_X))
    (jit-test-case '(BPF_ALU BPF_SUB BPF_X))
    (jit-test-case '(BPF_ALU BPF_AND BPF_X))
    (jit-test-case '(BPF_ALU BPF_OR BPF_X))
    (jit-test-case '(BPF_ALU BPF_XOR BPF_X))
    (jit-test-case '(BPF_ALU BPF_MUL BPF_X))
    (jit-test-case '(BPF_ALU BPF_LSH BPF_X))
    (jit-test-case '(BPF_ALU BPF_RSH BPF_X))
    (jit-test-case '(BPF_ALU BPF_ARSH BPF_X))
    (jit-test-case '(BPF_ALU BPF_NEG))
))

(module+ test
  (time (run-tests tests)))
