#lang rosette

(require
  "common.rkt"
  "riscv-common.rkt"
  rosette/lib/angelic
  serval/lib/unittest
  (prefix-in bpf: serval/bpf)
  (prefix-in riscv: serval/riscv/base)
  (prefix-in riscv: serval/riscv/interp))

(provide (all-defined-out))

(define regmap #(a5 a0 a1 a2 a3 a4 s1 s2 s3 s4 s5))

(define (bpf_to_rv_reg r)
  (vector-ref regmap r))

(struct context (insns) #:mutable #:transparent)

(define (emit insn ctx)
  (set-context-insns! ctx (append (context-insns ctx) (list insn))))

(define (emit_imm rd val ctx)
  (define upper (bvashr (bvadd val (bvshl (bv 1 32) (bv 11 32))) (bv 12 32)))
  (define lower (bvand val (bv #xfff 32)))
  (cond
    [(equal? upper (bv 0 32))
     (emit (rv_addi rd RV_REG_ZERO lower) ctx)]
    [else
     (emit (rv_lui rd upper) ctx)
     (emit (rv_addiw rd rd lower) ctx)]))

(define (emit_zext_32 reg ctx)
  (emit (rv_slli reg reg 32) ctx)
  (emit (rv_srli reg reg 32) ctx))

(define BPF_CLASS first)
(define BPF_OP second)
(define BPF_SRC last)

(define patch (make-parameter (if (getenv "DISABLE_PATCH") #f #t)))

(define-syntax-rule (with-patch body ...)
  (when (patch)
    body ...))

(define (run-jit code dst src off imm)
  (define ctx (context null))

  (define is64 (|| (equal? (BPF_CLASS code) 'BPF_ALU64)
                   (equal? (BPF_CLASS code) 'BPF_JMP)))

  ; TODO: add more checks as in init_regs
  (define rd (bpf_to_rv_reg dst))
  (define rs (bpf_to_rv_reg src))

  (match code
    ; dst = src
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_MOV 'BPF_X)
     (emit (if is64 (rv_addi rd rs 0) (rv_addiw rd rs 0)) ctx)
     (when (! is64)
       (emit_zext_32 rd ctx))]

    ; dst = dst OP src
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_ADD 'BPF_X)
     (emit (if is64 (rv_add rd rd rs) (rv_addw rd rd rs)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_SUB 'BPF_X)
     (emit (if is64 (rv_sub rd rd rs) (rv_subw rd rd rs)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_AND 'BPF_X)
     (emit (rv_and rd rd rs) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_OR 'BPF_X)
     (emit (rv_or rd rd rs) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_XOR 'BPF_X)
     (emit (rv_xor rd rd rs) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_MUL 'BPF_X)
     (emit (if is64 (rv_mul rd rd rs) (rv_mulw rd rd rs)) ctx)
     (when (! is64)
       (emit_zext_32 rd ctx))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_DIV 'BPF_X)
     (emit (if is64 (rv_divu rd rd rs) (rv_divuw rd rd rs)) ctx)
     (when (! is64)
       (emit_zext_32 rd ctx))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_MOD 'BPF_X)
     (emit (if is64 (rv_remu rd rd rs) (rv_remuw rd rd rs)) ctx)
     (when (! is64)
       (emit_zext_32 rd ctx))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_LSH 'BPF_X)
     (emit (if is64 (rv_sll rd rd rs) (rv_sllw rd rd rs)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_RSH 'BPF_X)
     (emit (if is64 (rv_srl rd rd rs) (rv_srlw rd rd rs)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_ARSH 'BPF_X)
     (emit (if is64 (rv_sra rd rd rs) (rv_sraw rd rd rs)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]

    ; dst = -dst
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_NEG)
     (emit (if is64 (rv_sub rd RV_REG_ZERO rd) (rv_subw rd RV_REG_ZERO rd)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]

    ; dst = BSWAP##imm(dst)
    [(list 'BPF_ALU 'BPF_END 'BPF_FROM_LE)
     (define shift (extract 11 0 (bvsub (bv 64 32) imm)))
     (emit (rv_slli rd rd shift) ctx)
     (emit (rv_srli rd rd shift) ctx)]
    [(list 'BPF_ALU 'BPF_END 'BPF_FROM_BE)
     (emit (rv_addi RV_REG_T2 RV_REG_ZERO 0) ctx)

     (emit (rv_andi RV_REG_T1 rd #xff) ctx)
     (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)
     (emit (rv_slli RV_REG_T2 RV_REG_T2 8) ctx)
     (emit (rv_srli rd rd 8) ctx)

     (when (not (equal? imm (bv 16 32)))
       (emit (rv_andi RV_REG_T1 rd #xff) ctx)
       (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)
       (emit (rv_slli RV_REG_T2 RV_REG_T2 8) ctx)
       (emit (rv_srli rd rd 8) ctx)

       (emit (rv_andi RV_REG_T1 rd #xff) ctx)
       (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)
       (emit (rv_slli RV_REG_T2 RV_REG_T2 8) ctx)
       (emit (rv_srli rd rd 8) ctx)

       (when (not (equal? imm (bv 32 32)))
         (emit (rv_andi RV_REG_T1 rd #xff) ctx)
         (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)
         (emit (rv_slli RV_REG_T2 RV_REG_T2 8) ctx)
         (emit (rv_srli rd rd 8) ctx)

         (emit (rv_andi RV_REG_T1 rd #xff) ctx)
         (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)
         (emit (rv_slli RV_REG_T2 RV_REG_T2 8) ctx)
         (emit (rv_srli rd rd 8) ctx)

         (emit (rv_andi RV_REG_T1 rd #xff) ctx)
         (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)
         (emit (rv_slli RV_REG_T2 RV_REG_T2 8) ctx)
         (emit (rv_srli rd rd 8) ctx)

         (emit (rv_andi RV_REG_T1 rd #xff) ctx)
         (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)
         (emit (rv_slli RV_REG_T2 RV_REG_T2 8) ctx)
         (emit (rv_srli rd rd 8) ctx)))

     (emit (rv_andi RV_REG_T1 rd #xff) ctx)
     (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)

     (emit (rv_addi rd RV_REG_T2 0) ctx)]

    ; dst = imm
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_MOV 'BPF_K)
     (emit_imm rd imm ctx)
     (when (! is64)
       (emit_zext_32 rd ctx))]

    ; dst = dst OP imm
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_ADD 'BPF_K)
     (cond
       [(is_12b_int imm)
        (emit (if is64 (rv_addi rd rd imm) (rv_addiw rd rd imm)) ctx)]
       [else
        (emit_imm RV_REG_T1 imm ctx)
        (emit (if is64 (rv_add rd rd RV_REG_T1) (rv_addw rd rd RV_REG_T1)) ctx)])
     (when (! is64)
         (emit_zext_32 rd ctx))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_LSH 'BPF_K)
     (emit (if is64 (rv_slli rd rd imm) (rv_slliw rd rd imm)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_RSH 'BPF_K)
     (emit (if is64 (rv_srli rd rd imm) (rv_srliw rd rd imm)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_ARSH 'BPF_K)
     (emit (if is64 (rv_srai rd rd imm) (rv_sraiw rd rd imm)) ctx)
     (with-patch
       (when (! is64)
         (emit_zext_32 rd ctx)))]
  )

  (context-insns ctx))

(define (cpu-equal? b r)
  (define regs
    (for/vector [(i (in-range (vector-length bpf-regs)))]
      (riscv:gpr-ref r (vector-ref regmap i))))
  (equal? (bpf:cpu-regs b) regs))

(define (init-rv64-cpu bpf-cpu)
  (define riscv-cpu (riscv:init-cpu))
  (for ([i (in-range (vector-length bpf-regs))])
    (riscv:gpr-set! riscv-cpu (vector-ref regmap i) (vector-ref bpf-regs i)))
  riscv-cpu)

(define (run-jitted-code riscv-cpu insns)
  ; run jitted code
  ; FIXME: check the pc after executing each instruction (assuming straightline)
  (for-each (lambda (i) (riscv:interpret-instr riscv-cpu i)) insns))


(define (check-jit code)
  (verify-jit-refinement
    code
    #:init-cpu init-rv64-cpu
    #:equiv cpu-equal?
    #:run-code run-jitted-code
    #:run-jit run-jit))

(define-syntax-rule (jit-test-case code)
  (test-case+ (format "~s" code) (check-jit code)))
