#lang rosette

(require
  rosette/lib/synthax
  rosette/lib/angelic
  rosette/solver/smt/boolector
  (prefix-in riscv: serval/riscv/base)
  (prefix-in riscv: serval/riscv/interp))

(define RV_REG_ZERO 'zero)
(define RV_REG_T1 't1)
(define RV_REG_T2 't2)

(define rd 'a0)

(struct context (insns) #:mutable #:transparent)

(define (emit insn ctx)
  (set-context-insns! ctx (append (context-insns ctx) (list insn))))

(define DEFAULT_SIZE 4)

(define (rv_r_insn rs2 rs1 rd opcode)
  (riscv:instr opcode rd rs1 rs2 #f DEFAULT_SIZE))

(define (rv_i_insn imm11_0 rs1 rd opcode)
  (riscv:instr opcode rd rs1 #f (if (integer? imm11_0) (bv imm11_0 12) (extract 11 0 imm11_0)) DEFAULT_SIZE))

(define (rv_u_insn imm31_12 rd opcode)
  (riscv:instr opcode rd #f #f (extract 19 0 imm31_12) DEFAULT_SIZE))

(define (rv_addiw rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'addiw))

(define (rv_addi rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'addi))

(define (rv_addw rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'addw))

(define (rv_add rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'add))

(define (rv_and rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'and))

(define (rv_or rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'or))

(define (rv_xor rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'xor))

(define (rv_sllw rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'sllw))

(define (rv_sll rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'sll))

(define (rv_srlw rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'srlw))

(define (rv_srl rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'srl))

(define (rv_sraw rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'sraw))

(define (rv_sra rd rs1 rs2)
  (rv_r_insn rs2 rs1 rd 'sra))

(define (rv_lui rd imm31_12)
  (rv_u_insn imm31_12 rd 'lui))

(define (rv_slli rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'slli))

(define (rv_andi rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'andi))

(define (rv_ori rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'ori))

(define (rv_xori rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'xori))

(define (rv_slliw rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'slliw))

(define (rv_srliw rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'srliw))

(define (rv_srli rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'srli))

(define (rv_sraiw rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'sraiw))

(define (rv_srai rd rs1 imm11_0)
  (rv_i_insn imm11_0 rs1 rd 'srai))

(define (jit ctx)
  (emit (rv_addi RV_REG_T2 RV_REG_ZERO 0) ctx)

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
         (emit (rv_srli rd rd 8) ctx)

  (emit (rv_andi RV_REG_T1 rd #xff) ctx)
  (emit (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1) ctx)

  (emit (rv_addi rd RV_REG_T2 0) ctx))

(define bswap16-insns (list
  ; (rv_addi RV_REG_T2 RV_REG_ZERO 0)

  ; (rv_andi RV_REG_T1 rd #xff)
  ; (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)

  ; synthesized
  (rv_andi RV_REG_T2 rd #xff)

  (rv_slli RV_REG_T2 RV_REG_T2 8)
  (rv_srli rd rd 8)

  (rv_andi RV_REG_T1 rd #xff)

  ;(rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
  ;(rv_addi rd RV_REG_T2 0)

  ; synthesized
  (rv_add rd RV_REG_T2 RV_REG_T1)
))

(define bswap32-insns (list
;  (rv_addi RV_REG_T2 RV_REG_ZERO 0)

;  (rv_andi RV_REG_T1 rd #xff)
;  (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)

; synthesized
  (rv_andi RV_REG_T2 rd #xff)

  (rv_slli RV_REG_T2 RV_REG_T2 8)
  (rv_srli rd rd 8)

       (rv_andi RV_REG_T1 rd #xff)
       (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
       (rv_slli RV_REG_T2 RV_REG_T2 8)
       (rv_srli rd rd 8)

       (rv_andi RV_REG_T1 rd #xff)
       (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
       (rv_slli RV_REG_T2 RV_REG_T2 8)
       (rv_srli rd rd 8)

  (rv_andi RV_REG_T1 rd #xff)

  ; (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
  ; (rv_addi rd RV_REG_T2 0)
  ; synthesized
  (rv_add rd RV_REG_T2 RV_REG_T1)
))

(define bswap64-insns (list
;  (rv_addi RV_REG_T2 RV_REG_ZERO 0)

;  (rv_andi RV_REG_T1 rd #xff)
;  (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)

; synthesized
  (rv_andi RV_REG_T2 rd #xff)

  (rv_slli RV_REG_T2 RV_REG_T2 8)
  (rv_srli rd rd 8)

       (rv_andi RV_REG_T1 rd #xff)
       (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
       (rv_slli RV_REG_T2 RV_REG_T2 8)
       (rv_srli rd rd 8)

       (rv_andi RV_REG_T1 rd #xff)
       (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
       (rv_slli RV_REG_T2 RV_REG_T2 8)
       (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

  ; (rv_andi RV_REG_T1 rd #xff)

  ; (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
  ; (rv_addi rd RV_REG_T2 0)

  ; synthesized
  (rv_add rd rd RV_REG_T2)
))

(define ctx (context null))
(jit ctx)
(define old-insns (context-insns ctx))

(define (run rs vs insns)
  (define cpu (riscv:init-cpu))
  (for [(r rs) (v vs)]
    (riscv:gpr-set! cpu r v))
  (for [(i insns)]
    (riscv:interpret-instr cpu i))
  (riscv:gpr-ref cpu (first rs)))

(define (choose-reg)
  (choose* rd RV_REG_ZERO RV_REG_T1 RV_REG_T2))

(define (choose-imm12)
  (define-symbolic* imm12 (bitvector 12))
  imm12)

(define (choose-instr)
  (define-symbolic* imm12 (bitvector 12))
  (riscv:instr
    (choose* 'addiw 'addi 'andi 'slliw 'slli 'srliw 'srli 'sraiw 'srai 'add 'addw)
    (choose-reg)
    (choose-reg)
    (choose-reg)
    imm12
    4))

(define new-insns (list
;  (rv_addi RV_REG_T2 RV_REG_ZERO 0)

;  (rv_andi RV_REG_T1 rd #xff)
;  (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)

; synthesized
  (rv_andi RV_REG_T2 rd #xff)

  (rv_slli RV_REG_T2 RV_REG_T2 8)
  (rv_srli rd rd 8)

       (rv_andi RV_REG_T1 rd #xff)
       (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
       (rv_slli RV_REG_T2 RV_REG_T2 8)
       (rv_srli rd rd 8)

       (rv_andi RV_REG_T1 rd #xff)
       (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
       (rv_slli RV_REG_T2 RV_REG_T2 8)
       (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

         (rv_andi RV_REG_T1 rd #xff)
         (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
         (rv_slli RV_REG_T2 RV_REG_T2 8)
         (rv_srli rd rd 8)

  (choose-instr)
  ; (rv_andi RV_REG_T1 rd #xff)

  ; (rv_add RV_REG_T2 RV_REG_T2 RV_REG_T1)
  ; (rv_addi rd RV_REG_T2 0)

  ; synthesized
  ; (rv_add rd rd RV_REG_T2)
))

(define-symbolic v-rd v-t0 v-t1 (bitvector 64))

(define rs (list rd RV_REG_T1 RV_REG_T2))
(define vs (list v-rd v-t0 v-t1))

(let [(boolector-path (getenv "BOOLECTOR"))]
  (when boolector-path
    (current-solver (boolector #:path boolector-path))))
(current-bitwidth 12)
(displayln (format "running ~a" (current-solver)))

(define sol
  (synthesize
   #:forall vs
   #:guarantee (assert (equal? (run rs vs old-insns) (run rs vs new-insns)))))

(if (sat? sol)
    (for [(i (evaluate new-insns sol))]
      (displayln i))
    (displayln "no solution!"))
