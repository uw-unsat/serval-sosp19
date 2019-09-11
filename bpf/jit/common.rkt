#lang rosette

(require
  (prefix-in bpf: serval/bpf)
  rosette/solver/smt/boolector
  rosette/lib/angelic
  serval/lib/unittest)

(provide (all-defined-out))

; BPF registers
(define-symbolic pc r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 (bitvector 64))
(define bpf-regs (vector r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10))

(define BPF_CLASS first)
(define BPF_OP second)
(define BPF_SRC last)

(define BPF_REG_0 0)
(define BPF_REG_1 1)
(define BPF_REG_2 2)
(define BPF_REG_3 3)
(define BPF_REG_4 4)
(define BPF_REG_5 5)
(define BPF_REG_6 6)
(define BPF_REG_7 7)
(define BPF_REG_8 8)
(define BPF_REG_9 9)
(define BPF_REG_FP 10)
(define TMP_REG_1 11)
(define TMP_REG_2 12)

(define (alu64? code)
  (equal? (BPF_CLASS code) 'BPF_ALU64))

(define (alu32? code)
  (equal? (BPF_CLASS code) 'BPF_ALU))

(define (shift? code)
  (case (BPF_OP code)
    [(BPF_LSH BPF_RSH BPF_ARSH) #t]
    [else #f]))

(define (div? code)
  (case (BPF_OP code)
    [(BPF_DIV BPF_MOD) #t]
    [else #f]))

(define (endian? code)
  (equal? (BPF_OP code) 'BPF_END))

(define (src-x? code)
  (equal? (BPF_SRC code) 'BPF_X))

(define (src-k? code)
  (equal? (BPF_SRC code) 'BPF_K))

(define
  (verify-jit-refinement
    code
    #:equiv cpu-equal? ; bpf_cpu -> ARCH_CPU -> bool
    #:run-jit run-jit
    #:run-code run-jitted-code
    #:init-cpu init-cpu
    #:verify? [verify? #t])

    (define dst (apply choose* (range 5)))
    (define src (apply choose* (range 5)))

    (for/all ([dst dst #:exhaustive])
      (for/all ([src src #:exhaustive])
      (begin

        ; set up bpf
        (define bpf-cpu (bpf:init-cpu))
        (bpf:set-cpu-pc! bpf-cpu pc)
        (bpf:set-cpu-regs! bpf-cpu
          (if verify? (vector-copy bpf-regs) (arbitrary bpf-regs)))

        ; Create architecture cpu
        (define arch-cpu (init-cpu bpf-cpu))

        ; Verify initial states match
        (check-unsat? (verify (assert (cpu-equal? bpf-cpu arch-cpu))))

        (define-symbolic* off (bitvector 16))
        (define-symbolic* imm (bitvector 32))

        (define dst-op (vector-ref bpf-regs dst))
        (define src-op (vector-ref bpf-regs src))

        ; Programs accepted by checker should satisfy these preconditions
        (define pre (&& (>= dst 0) (< dst 10)
                        (>= src 0) (<= src 10)
                        ; Assume divisor is non-zero
                        (=> (&& (alu32? code) (div? code) (src-x? code)) (! (bveq (extract 31 0 src-op) (bv 0 32))))
                        (=> (&& (alu64? code) (div? code) (src-x? code)) (! (bveq src-op (bv 0 64))))
                        (=> (&& (alu32? code) (div? code) (src-k? code)) (! (bveq imm (bv 0 32))))
                        (=> (&& (alu64? code) (div? code) (src-k? code)) (! (bveq imm (bv 0 32))))
                        ; assume the shifting amount is in-bounds
                        (=> (&& (alu32? code) (shift? code) (src-x? code)) (bvult src-op (bv 32 64)))
                        (=> (&& (alu64? code) (shift? code) (src-x? code)) (bvult src-op (bv 64 64)))
                        (=> (&& (alu32? code) (shift? code) (src-k? code)) (bvult imm (bv 32 32)))
                        (=> (&& (alu64? code) (shift? code) (src-k? code)) (bvult imm (bv 64 32)))
                        ; assume the endianness imm is one of 16, 32, 64
                        ; (=> (endian? code) (|| (equal? imm (bv 16 32)) (equal? imm (bv 32 32)) (equal? imm (bv 64 32))))
                        (=> (endian? code) (equal? imm (bv 16 32)))

        ))

        (check-sat? (solve (assert pre)))

        ; run jit
        (define insns (run-jit code dst src off imm))

        ; run bpf
        (bpf:interpret-instr bpf-cpu code dst src off imm)

        ; run jitted code
        (run-jitted-code arch-cpu insns)

        ; check if final states match
        (check-unsat? (verify (assert (implies pre (cpu-equal? bpf-cpu arch-cpu)))))

        ; no undefined behavior
        (define asserted (asserts))
        (clear-asserts!)
        (for ([e asserted])
          (check-unsat? (verify (assert (implies pre e)))))))))