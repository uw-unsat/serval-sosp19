#lang rosette

(require
  rosette/lib/angelic
  serval/lib/unittest
  "emit.rkt"
  "common.rkt"
  "riscv-common.rkt"
  (prefix-in core: serval/lib/core)
  (prefix-in bpf: serval/bpf)
  (prefix-in riscv: serval/riscv/interp)
  (prefix-in riscv: serval/riscv/base))

(provide (all-defined-out))

(define STACK_SIZE 32)

(define (stack-offset k)
  (- (- 4) (* k 4)))

(define regmap
  #((s2 . s1) ; R0
    (a1 . a0) ; R1
    (a3 . a2) ; R2
    (a5 . a4) ; R3
    (a7 . a6) ; R4
    (s4 . s3) ; R5
    (0 . 1) ; R6
    (2 . 3) ; R7
    (4 . 5) ; R8
    (6 . 7) ; R9
    (s6 . s5) ; FP
    (t3 . t2) ; TMP1
    (t5 . t4) ; TMP2
    (8 . 9) ; TCALL
    (10 . 11) ; AX
  ))

(define (bpf_to_rv_regs r)
  (vector-ref regmap r))

(define (hi x) (car x))
(define (lo x) (cdr x))

(define (bpf_to_rv_reg_lo r)
  (cdr (bpf_to_rv_regs r)))

(define (bpf_to_rv_reg_hi r)
  (car (bpf_to_rv_regs r)))

(struct context (insns) #:mutable #:transparent)

(define (emit insn ctx)
  (set-context-insns! ctx (vector-append (context-insns ctx) (vector insn))))

(define (emit_imm rd val ctx)
  (define upper (bvashr (bvadd val (bvshl (bv 1 32) (bv 11 32))) (bv 12 32)))
  (define lower (bvand val (bv #xfff 32)))
  (cond
    [(equal? upper (bv 0 32))
     (emit (rv_addi rd RV_REG_ZERO lower) ctx)]
    [else
     (emit (rv_lui rd upper) ctx)
     (emit (rv_addi rd rd lower) ctx)]))

(define (emit_imm32 rd imm ctx)
  (emit_imm (lo rd) imm ctx)
  (if (bvsge imm (bv 0 32))
    (emit (rv_addi (hi rd) RV_REG_ZERO 0) ctx)
    (emit (rv_addi (hi rd) RV_REG_ZERO -1) ctx)))

(define (comment s)
  (void))

(define patch (make-parameter #t))

(define-syntax-rule (with-patch body ...)
  (when (patch)
    body ...))

(define (is_stacked r)
  (integer? r))

(define (riscv_bpf_get_reg64 reg tmp ctx)
  (assert (<=> (is_stacked (hi reg)) (is_stacked (lo reg))))
  (assert (&& (! (is_stacked (hi tmp))) (! (is_stacked (lo tmp)))))
  (cond
    [(is_stacked (hi reg))
      (emit (rv_lw (hi tmp) (stack-offset (hi reg)) RV_FP) ctx)
      (emit (rv_lw (lo tmp) (stack-offset (lo reg)) RV_FP) ctx)
      tmp]
    [else reg]))

(define (riscv_bpf_get_reg32 reg tmp ctx)
  (cond
    [(is_stacked (lo reg))
      (emit (rv_lw (lo tmp) (stack-offset (lo reg)) RV_FP) ctx)
      tmp]
    [else reg]))

(define (riscv_bpf_put_reg64 reg src ctx)
  (cond
    [(is_stacked (hi reg))
      (emit (rv_sw RV_FP (stack-offset (hi reg)) (hi src)) ctx)
      (emit (rv_sw RV_FP (stack-offset (lo reg)) (lo src)) ctx)]
    [(! (equal? (hi reg) (hi src)))
      (emit (rv_addi (hi reg) (hi src) 0) ctx)
      (emit (rv_addi (lo reg) (lo src) 0) ctx)]
    [else (void)]))

(define (riscv_bpf_put_reg32 reg src ctx)
  (cond
    [(is_stacked (hi reg))
      (emit (rv_sw RV_FP (stack-offset (hi reg)) RV_REG_ZERO) ctx)
      (emit (rv_sw RV_FP (stack-offset (lo reg)) (lo src)) ctx)]
    [else
      (emit (rv_addi (hi reg) RV_REG_ZERO 0) ctx)
      (emit (rv_addi (lo reg) (lo src) 0) ctx)]))


(define (emit_rv32_alu_i64 dst imm ctx op)
  (define tmp1 (bpf_to_rv_regs TMP_REG_1))

  (define rd (riscv_bpf_get_reg64 dst tmp1 ctx))

  (switch op #:id SWITCH_emit_rv32_alu_i64
    [(BPF_MOV)
      (emit_imm32 rd imm ctx)]

    [(BPF_AND)
      (cond
        [(is_12b_int imm)
          (emit (rv_andi (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_and (lo rd) (lo rd) RV_REG_T0) ctx)])
      (when (bvsge imm (bv 0 32))
        (emit (rv_addi (hi rd) RV_REG_ZERO 0) ctx))]

    [(BPF_OR)
      (cond
        [(is_12b_int imm)
          (emit (rv_ori (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_or (lo rd) (lo rd) RV_REG_T0) ctx)])
      (when (bvslt imm (bv 0 32))
        (emit (rv_ori (hi rd) RV_REG_T0 -1) ctx)
        (emit (rv_ori (hi rd) RV_REG_T0 -1) ctx))]

    [(BPF_XOR)
      (cond
        [(is_12b_int imm)
          (emit (rv_xori (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_xor (lo rd) (lo rd) RV_REG_T0) ctx)])
      (when (bvslt imm (bv 0 32))
        (emit (rv_xori (hi rd) (hi rd) -1) ctx))]

    [(BPF_LSH)
      (cond
        [(bvuge imm (bv 32 32))
          (emit (rv_slli (hi rd) (lo rd) (bvsub imm (bv 32 32))) ctx)
          (emit (rv_addi (lo rd) RV_REG_ZERO 0) ctx)]
        [(equal? imm (bv 0 32))
          (comment "/* nop */")]
        [else
          (emit (rv_srli RV_REG_T0 (lo rd) (bvsub (bv 32 32) imm)) ctx)
          (emit (rv_slli (hi rd) (hi rd) imm) ctx)
          (emit (rv_or (hi rd) RV_REG_T0 (hi rd)) ctx)
          (emit (rv_slli (lo rd) (lo rd) imm) ctx)])]

    [(BPF_RSH)
      (cond
        [(bvuge imm (bv 32 32))
          (emit (rv_srli (lo rd) (hi rd) (bvsub imm (bv 32 32))) ctx)
          (emit (rv_addi (hi rd) RV_REG_ZERO 0) ctx)]
        [(equal? imm (bv 0 32))
          (comment "/* nop */")]
        [else
          (emit (rv_slli RV_REG_T0 (hi rd) (bvsub (bv 32 32) imm)) ctx)
          (emit (rv_srli (lo rd) (lo rd) imm) ctx)
          (emit (rv_or (lo rd) RV_REG_T0 (lo rd)) ctx)
          (emit (rv_srli (hi rd) (hi rd) imm) ctx)])]

    [(BPF_ARSH)
      (cond
        [(bvuge imm (bv 32 32))
          (emit (rv_srai (lo rd) (hi rd) (bvsub imm (bv 32 32))) ctx)
          (emit (rv_srai (hi rd) (hi rd) 31) ctx)]
        [(equal? imm (bv 0 32))
          (comment "/* nop */")]
        [else
          (emit (rv_slli RV_REG_T0 (hi rd) (bvsub (bv 32 32) imm)) ctx)
          (emit (rv_srli (lo rd) (lo rd) imm) ctx)
          (emit (rv_or (lo rd) RV_REG_T0 (lo rd)) ctx)
          (emit (rv_srai (hi rd) (hi rd) imm) ctx)])]
    )

  (riscv_bpf_put_reg64 dst rd ctx))


(define (emit_rv32_alu_i32 dst imm ctx op)
  (define tmp1 (bpf_to_rv_regs TMP_REG_1))

  (define rd (riscv_bpf_get_reg32 dst tmp1 ctx))

  (switch op #:id SWITCH_emit_rv32_alu_i32
    [(BPF_MOV)
      (emit_imm (lo rd) imm ctx)]
    [(BPF_ADD)
      (cond
        [(is_12b_int imm)
          (emit (rv_addi (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_add (lo rd) (lo rd) RV_REG_T0) ctx)])]
    [(BPF_SUB)
      (cond
        [(is_12b_int (bvneg imm))
          (emit (rv_addi (lo rd) (lo rd) (bvneg imm)) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_sub (lo rd) (lo rd) RV_REG_T0) ctx)])]
    [(BPF_AND)
      (cond
        [(is_12b_int imm)
          (emit (rv_andi (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_and (lo rd) (lo rd) RV_REG_T0) ctx)])]
    [(BPF_OR)
      (cond
        [(is_12b_int imm)
          (emit (rv_ori (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_or (lo rd) (lo rd) RV_REG_T0) ctx)])]
    [(BPF_XOR)
      (cond
        [(is_12b_int imm)
          (emit (rv_xori (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_xor (lo rd) (lo rd) RV_REG_T0) ctx)])]
    [(BPF_LSH)
      (cond
        [(is_12b_int imm)
          (emit (rv_slli (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_sll (lo rd) (lo rd) RV_REG_T0) ctx)])]
    [(BPF_RSH)
      (cond
        [(is_12b_int imm)
          (emit (rv_srli (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_srl (lo rd) (lo rd) RV_REG_T0) ctx)])]
    [(BPF_ARSH)
      (cond
        [(is_12b_int imm)
          (emit (rv_srai (lo rd) (lo rd) imm) ctx)]
        [else
          (emit_imm RV_REG_T0 imm ctx)
          (emit (rv_sra (lo rd) (lo rd) RV_REG_T0) ctx)])]
  )

  (riscv_bpf_put_reg32 dst rd ctx))


(define (emit_rv32_alu_r64 dst src ctx op)
  (define tmp1 (bpf_to_rv_regs TMP_REG_1))
  (define tmp2 (bpf_to_rv_regs TMP_REG_2))

  (define rd (riscv_bpf_get_reg64 dst tmp1 ctx))
  (define rs (riscv_bpf_get_reg64 src tmp2 ctx))

  (switch op #:id SWITCH_emit_rv32_alu_r64
    [(BPF_MOV)
      (emit (rv_addi (lo rd) (lo rs) 0) ctx)
      (emit (rv_addi (hi rd) (hi rs) 0) ctx)]

    [(BPF_ADD)
      (emit (rv_addi RV_REG_T0 (lo rd) 0) ctx)
      (emit (rv_add (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_sltu RV_REG_T0 (lo rd) RV_REG_T0) ctx)
      (emit (rv_add (hi rd) (hi rd) (hi rs)) ctx)
      (emit (rv_add (hi rd) (hi rd) RV_REG_T0) ctx)]

    [(BPF_SUB)
      (emit (rv_addi RV_REG_T0 (lo rd) 0) ctx)
      (emit (rv_sub (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_sltu RV_REG_T0 RV_REG_T0 (lo rd)) ctx)
      (emit (rv_sub (hi rd) (hi rd) (hi rs)) ctx)
      (emit (rv_sub (hi rd) (hi rd) RV_REG_T0) ctx)]

    [(BPF_AND)
      (emit (rv_and (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_and (hi rd) (hi rd) (hi rs)) ctx)]

    [(BPF_OR)
      (emit (rv_or (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_or (hi rd) (hi rd) (hi rs)) ctx)]

    [(BPF_XOR)
      (emit (rv_xor (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_xor (hi rd) (hi rd) (hi rs)) ctx)]

    [(BPF_MUL)
      (emit (rv_mul RV_REG_T0 (hi rs) (lo rd)) ctx)
      (emit (rv_mul (hi rd) (hi rd) (lo rs)) ctx)
      (emit (rv_mulhu RV_REG_T1 (lo rd) (lo rs)) ctx)
      (emit (rv_add (hi rd) (hi rd) RV_REG_T0) ctx)
      (emit (rv_mul (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_add (hi rd) (hi rd) RV_REG_T1) ctx)]

    [(BPF_LSH)
      (emit (rv_addi RV_REG_T0 (lo rs) -32) ctx)
      (emit (rv_blt RV_REG_T0 RV_REG_ZERO 8) ctx)

      (emit (rv_sll (hi rd) (lo rd) RV_REG_T0) ctx)
      (emit (rv_addi (lo rd) RV_REG_ZERO 0) ctx)
      (emit (rv_jal RV_REG_ZERO 16) ctx)

      (emit (rv_addi RV_REG_T1 RV_REG_ZERO 31) ctx)
      (emit (rv_srli RV_REG_T0 (lo rd) 1) ctx)
      (emit (rv_sub RV_REG_T1 RV_REG_T1 (lo rs)) ctx)
      (emit (rv_srl RV_REG_T0 RV_REG_T0 RV_REG_T1) ctx)
      (emit (rv_sll (hi rd) (hi rd) (lo rs)) ctx)
      (emit (rv_or (hi rd) RV_REG_T0 (hi rd)) ctx)
      (emit (rv_sll (lo rd) (lo rd) (lo rs)) ctx)]

    [(BPF_RSH)
      (emit (rv_addi RV_REG_T0 (lo rs) -32) ctx)
      (emit (rv_blt RV_REG_T0 RV_REG_ZERO 8) ctx)

      (emit (rv_srl (lo rd) (hi rd) RV_REG_T0) ctx)
      (emit (rv_addi (hi rd) RV_REG_ZERO 0) ctx)
      (emit (rv_jal RV_REG_ZERO 16) ctx)

      (emit (rv_addi RV_REG_T1 RV_REG_ZERO 31) ctx)
      (emit (rv_slli RV_REG_T0 (hi rd) 1) ctx)
      (emit (rv_sub RV_REG_T1 RV_REG_T1 (lo rs)) ctx)
      (emit (rv_sll RV_REG_T0 RV_REG_T0 RV_REG_T1) ctx)
      (emit (rv_srl (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_or (lo rd) RV_REG_T0 (lo rd)) ctx)
      (emit (rv_srl (hi rd) (hi rd) (lo rs)) ctx)]

    [(BPF_ARSH)
      (emit (rv_addi RV_REG_T0 (lo rs) -32) ctx)
      (emit (rv_blt RV_REG_T0 RV_REG_ZERO 8) ctx)

      (emit (rv_sra (lo rd) (hi rd) RV_REG_T0) ctx)
      (emit (rv_srai (hi rd) (hi rd) #x1f) ctx)
      (emit (rv_jal RV_REG_ZERO 16) ctx)

      (emit (rv_addi RV_REG_T1 RV_REG_ZERO 31) ctx)
      (emit (rv_slli RV_REG_T0 (hi rd) 1) ctx)
      (emit (rv_sub RV_REG_T1 RV_REG_T1 (lo rs)) ctx)
      (emit (rv_sll RV_REG_T0 RV_REG_T0 RV_REG_T1) ctx)
      (emit (rv_srl (lo rd) (lo rd) (lo rs)) ctx)
      (emit (rv_or (lo rd) RV_REG_T0 (lo rd)) ctx)
      (emit (rv_sra (hi rd) (hi rd) (lo rs)) ctx)]

    [(BPF_NEG)
      (emit (rv_sub (lo rd) RV_REG_ZERO (lo rd)) ctx)
      (emit (rv_sltu RV_REG_T0 RV_REG_ZERO (lo rd)) ctx)
      (emit (rv_sub (hi rd) RV_REG_ZERO (hi rd)) ctx)
      (emit (rv_sub (hi rd) (hi rd) RV_REG_T0) ctx)]
  )

  (riscv_bpf_put_reg64 dst rd ctx))


(define (emit_rv32_alu_r32 dst src ctx op)
  (define tmp1 (bpf_to_rv_regs TMP_REG_1))
  (define tmp2 (bpf_to_rv_regs TMP_REG_2))

  (define rd (riscv_bpf_get_reg32 dst tmp1 ctx))
  (define rs (riscv_bpf_get_reg32 src tmp2 ctx))

  (switch op #:id SWITCH_emit_rv32_alu_r32
    [(BPF_MOV)
      (emit (rv_addi (lo rd) (lo rs) 0) ctx)]
    [(BPF_ADD)
      (emit (rv_add (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_SUB)
      (emit (rv_sub (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_AND)
      (emit (rv_and (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_OR)
      (emit (rv_or (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_XOR)
      (emit (rv_xor (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_MUL)
      (emit (rv_mul (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_DIV)
      (emit (rv_divu (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_MOD)
      (emit (rv_remu (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_LSH)
      (emit (rv_sll (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_RSH)
      (emit (rv_srl (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_ARSH)
      (emit (rv_sra (lo rd) (lo rd) (lo rs)) ctx)]
    [(BPF_NEG)
      (emit (rv_sub (lo rd) RV_REG_ZERO (lo rd)) ctx)]
  )

  (riscv_bpf_put_reg32 dst rd ctx))

(define (emit_rv32_rev16 rd ctx)
  (emit (rv_slli rd rd 16) ctx)
  (emit (rv_slli RV_REG_T1 rd 8) ctx)
  (emit (rv_srli rd rd 8) ctx)
  (emit (rv_add RV_REG_T1 rd RV_REG_T1) ctx)
  (emit (rv_srli rd RV_REG_T1 16) ctx))

(define (run-jit code dst src off imm)
  (define ctx (context (vector)))

  (define is64 (|| (equal? (BPF_CLASS code) 'BPF_ALU64)
                   (equal? (BPF_CLASS code) 'BPF_JMP)))

  (match code

    [(list 'BPF_ALU64 (and code (or 'BPF_LSH 'BPF_RSH 'BPF_ARSH 'BPF_ADD 'BPF_SUB 'BPF_AND 'BPF_OR 'BPF_XOR 'BPF_MUL 'BPF_MOV)) 'BPF_X)
      (emit_rv32_alu_r64 (bpf_to_rv_regs dst) (bpf_to_rv_regs src) ctx code)]

    [(list 'BPF_ALU64 (and code (or 'BPF_ADD 'BPF_SUB 'BPF_MUL)) 'BPF_K)
      (define tmp2 (vector-ref regmap TMP_REG_2))
      (emit_imm32 tmp2 imm ctx)
      (emit_rv32_alu_r64 (bpf_to_rv_regs dst) tmp2 ctx code)]

    [(list 'BPF_ALU64 (and code (or 'BPF_MOV 'BPF_AND 'BPF_OR 'BPF_XOR 'BPF_LSH 'BPF_RSH 'BPF_ARSH)) 'BPF_K)
      (emit_rv32_alu_i64 (bpf_to_rv_regs dst) imm ctx code)]

    [(list 'BPF_ALU64 (and code (or 'BPF_NEG)))
      (emit_rv32_alu_r64 (bpf_to_rv_regs dst) (bpf_to_rv_regs 0) ctx code)]

    [(list 'BPF_ALU (and code (or 'BPF_DIV 'BPF_MOD 'BPF_LSH 'BPF_RSH 'BPF_ARSH 'BPF_ADD 'BPF_SUB 'BPF_AND 'BPF_OR 'BPF_XOR 'BPF_MUL 'BPF_MOV)) 'BPF_X)
      (emit_rv32_alu_r32 (bpf_to_rv_regs dst) (bpf_to_rv_regs src) ctx code)]

    [(list 'BPF_ALU (and code (or 'BPF_DIV 'BPF_MOD 'BPF_MUL)) 'BPF_K)
      (define tmp2 (vector-ref regmap TMP_REG_2))
      (emit_imm32 tmp2 imm ctx)
      (emit_rv32_alu_r32 (bpf_to_rv_regs dst) tmp2 ctx code)]

    [(list 'BPF_ALU (and code (or 'BPF_MOV 'BPF_ADD 'BPF_SUB 'BPF_AND 'BPF_OR 'BPF_XOR 'BPF_LSH 'BPF_RSH 'BPF_ARSH)) 'BPF_K)
      (emit_rv32_alu_i32 (bpf_to_rv_regs dst) imm ctx code)]

    [(list 'BPF_ALU (and code (or 'BPF_NEG)))
      (emit_rv32_alu_r32 (bpf_to_rv_regs dst) (bpf_to_rv_regs 0) ctx code)]

    [(list 'BPF_ALU 'BPF_END 'BPF_FROM_BE)
      (define tmp1 (bpf_to_rv_regs TMP_REG_1))
      (define rd (riscv_bpf_get_reg64 (bpf_to_rv_regs dst) tmp1 ctx))

      (cond
        [(equal? imm (bv 16 32))
          (emit_rv32_rev16 (lo rd) ctx)
          (emit (rv_addi (hi rd) RV_REG_ZERO 0) ctx)])

      (riscv_bpf_put_reg64 (bpf_to_rv_regs dst) rd ctx)]

  )

  (context-insns ctx))


(define (cpu-equal? b r)
  (define stack-block (core:find-block-by-name (riscv:cpu-mregions r) 'stack))

  (define regs
    (for/vector [(i 11)]
      (define loreg (bpf_to_rv_reg_lo i))
      (define hireg (bpf_to_rv_reg_hi i))
      (define loval (if (integer? loreg)
        (core:mblock-iload stack-block (list (bv (- (- STACK_SIZE 1) loreg) 32)))
        (riscv:gpr-ref r loreg)))
      (define hival (if (integer? hireg)
        (core:mblock-iload stack-block (list (bv (- (- STACK_SIZE 1) hireg) 32)))
        (riscv:gpr-ref r hireg)))
      (concat hival loval)))
  (equal? (bpf:cpu-regs b) regs))

(define (make-riscv-program base instrs)
  (define current base)
  (define mret (riscv:instr 'mret #f #f #f #f 4))
  (define code
    (for/all ([instrs instrs #:exhaustive])
      (for/hash ([i (vector-append instrs (vector mret))])
        (define addr current)
        (set! current (bvadd current (bv (riscv:instr-size i) 32)))
        (values addr i))))
  (riscv:program base code))

(define (init-rv32-cpu bpf-cpu)
  (define globals (make-hash (list (cons 'stack (thunk (core:marray STACK_SIZE (core:mcell 4)))))))
  (define stack-top (+ #x1000 (* 4 STACK_SIZE)))
  (define symbols `((#x1000 ,stack-top B stack)))
  (define riscv-cpu (riscv:init-cpu symbols globals))
  (riscv:gpr-set! riscv-cpu 'fp (bv stack-top (riscv:XLEN)))

  (define stack-block (core:find-block-by-name (riscv:cpu-mregions riscv-cpu) 'stack))

  (for ([i (in-range (vector-length bpf-regs))])
    (define loreg (bpf_to_rv_reg_lo i))
    (define loval (extract 31 0 (vector-ref bpf-regs i)))
    (define hireg (bpf_to_rv_reg_hi i))
    (define hival (extract 63 32 (vector-ref bpf-regs i)))
    (if (integer? loreg)
      (core:mblock-istore! stack-block loval (list (bv (- (- STACK_SIZE 1) loreg) 32)))
      (riscv:gpr-set! riscv-cpu loreg loval))
    (if (integer? hireg)
      (core:mblock-istore! stack-block hival (list (bv (- (- STACK_SIZE 1) hireg) 32)))
      (riscv:gpr-set! riscv-cpu hireg hival)))

  riscv-cpu)

(define (run-jitted-code riscv-cpu insns)
  (define riscv-program (make-riscv-program (bv #x80000000 32) insns))
  (for/all ([insns (riscv:program-instructions riscv-program) #:exhaustive])
    (riscv:interpret-program riscv-cpu
      (riscv:program (riscv:program-base riscv-program) insns))))

(define (check-jit code)
  (parameterize
    ([riscv:XLEN 32]
     [core:target-pointer-bitwidth 32])
      (verify-jit-refinement
        code
        #:init-cpu init-rv32-cpu
        #:equiv cpu-equal?
        #:run-code run-jitted-code
        #:run-jit run-jit)))

(define-syntax-rule (jit-test-case code)
  (test-case+ (format "~s" code) (check-jit code)))
