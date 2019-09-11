#lang rosette

(require
  rosette/solver/smt/boolector
  serval/lib/unittest
  (prefix-in bpf: serval/bpf)
  (prefix-in riscv: serval/riscv/base)
  (prefix-in riscv: serval/riscv/interp)
  rosette/lib/synthax
  rosette/lib/angelic)

(riscv:XLEN 32)

(struct instr-template (op rd rs1 rs2 imm) #:transparent)
(struct branch-template (cond branchtrue branchfalse) #:transparent)

(define (choose-reg)
  (choose*
    'tmp ; A temporary register
    'tmp2 ; another tmp register
    'zero ; The RISC-V x0 register
    (list (choose* 'hi 'lo) ; Either the hi or lo bits...
          (choose* 'dst 'src)))) ; of either the dst or src reg.

(define (choose-imm)
  (define-symbolic* imm12 (bitvector 12))
  (define-symbolic* imm20 (bitvector 20))
  (choose*
    ; 'imm11:0 ; Either the imm from BPF instr
    imm12 ; or a fresh 12-bit int
    ; imm20 ; or a fresh 20-bit int
  ))

(define (choose-instr)
  (instr-template
    (choose* 'add 'slli 'srli 'andi) ; op
    (choose-reg) ; rd
    (choose-reg) ; rs1
    (choose-reg) ; rs2
    (choose-imm) ; imm
  ))

(define (interpret-imm imm-template imm)
  (cond
    [(equal? imm-template 'imm11:0) (extract 11 0 imm)]
    [#t imm-template]))

(define regmap '((a1 . a0) (a3 . a2)))

(define (interpret-reg reg-template dst src)
  (case reg-template
    [(zero) 'zero]
    [(tmp) 't0]
    [(tmp2) 't1]
    [((hi dst)) (car (list-ref regmap dst))]
    [((lo dst)) (cdr (list-ref regmap dst))]
    [((hi src)) (car (list-ref regmap src))]
    [((lo src)) (cdr (list-ref regmap src))]))

(define (interpret-instr template dst src imm)
  (riscv:instr
    (instr-template-op template)
    (interpret-reg (instr-template-rd template) dst src)
    (interpret-reg (instr-template-rs1 template) dst src)
    (interpret-reg (instr-template-rs2 template) dst src)
    (interpret-imm (instr-template-imm template) imm)
    4))


(define (choose-branch)
  (branch-template (choose* 'true)
    (list
      (choose-instr)
      (choose-instr)
      (choose-instr)
      (choose-instr)
      (choose-instr)
      (instr-template 'addi '(hi dst) 'zero 'zero (bv 0 12))
    )
    (list
    )
  ))


(define (interpret-branch template dst src imm)
  (if
    (case (branch-template-cond template)
      [(true) #t]
      [(noalias) (! (= dst src))])
    (map (lambda (n) (interpret-instr n dst src imm)) (branch-template-branchtrue template))
    (map (lambda (n) (interpret-instr n dst src imm)) (branch-template-branchfalse template))))


(define (synthesize-op op)
  (define riscv-cpu (riscv:init-cpu))

  (define-symbolic pc r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 (bitvector 64))
  (define bpf-regs (vector r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10))
  (define bpf-cpu (bpf:init-cpu))
  (bpf:set-cpu-pc! bpf-cpu (bv 0 64))
  (bpf:set-cpu-regs! bpf-cpu bpf-regs)

  (define (cpu-equal?)
    (apply &&
      (for/list ([i '(0 1)])
        (equal?
          (vector-ref (bpf:cpu-regs bpf-cpu) i)
          (concat (riscv:gpr-ref riscv-cpu (car (list-ref regmap i)))
                  (riscv:gpr-ref riscv-cpu (cdr (list-ref regmap i))))))))

  (define syms (append (symbolics riscv-cpu) (symbolics bpf-regs)))

  (define-symbolic dst src integer?)
  (define imm (bv 16 32))
  ; (define-symbolic imm (bitvector 32))

  (define pre
    (&& (cpu-equal?)
        (>= dst 0) (< dst 2)
        (>= src 0) (< src 2)))

  (bpf:interpret-instr bpf-cpu op dst src (bv 0 16) imm)

  (define jit (choose-branch))
  (define instrs (interpret-branch jit dst src imm))

  (for/all ([instrs instrs #:exhaustive])
    (for ([i instrs])
      (riscv:interpret-instr riscv-cpu i)))

  (define post (cpu-equal?))

  (let [(boolector-path (getenv "BOOLECTOR"))]
    (when boolector-path
      (current-solver (boolector #:path boolector-path))))
  (current-bitwidth 12)
  (displayln (format "running ~a" (current-solver)))

  (check-unsat (verify (assert (apply && (asserts)))))

  (define sol
    (synthesize
    #:forall (append syms (list dst src imm))
    #:guarantee (assert (=> pre post))))

  (if (sat? sol)
    (evaluate jit sol)
    #f))

(define (regstr r)
  (case r
    [(tmp) "t0"]
    [(tmp2) "t1"]
    [(zero) "x0"]
    [((hi src)) "hi(src)"]
    [((lo src)) "lo(src)"]
    [((hi dst)) "hi(dst)"]
    [((lo dst)) "lo(dst)"]))

(define (immstr r)
  (format "0x~x" (bitvector->natural r)))

(define (instrstr i)
  (format "    emit(rv_~s(~a, ~a, ~a, ~a), ctx);"
    (instr-template-op i)
    (regstr (instr-template-rd i))
    (regstr (instr-template-rs1 i))
    (regstr (instr-template-rs2 i))
    (immstr (instr-template-imm i))))

(define (branchstr b)
  (format "  if (~a) {\n~a  } else {\n~a  }\n"
    (case (branch-template-cond b)
      [(true) "true"]
      [(noalias) "dst != src"])
    (string-join (map instrstr (branch-template-branchtrue b)) "\n" #:after-last "\n")
    (string-join (map instrstr (branch-template-branchfalse b)) "\n" #:after-last "\n")))

(define (printsol j)
  (printf "void emit_op(u8 dst, u8 src, s32 imm, struct rv_jit_context *ctx) {\n")
  (printf "~a" (branchstr j))
  (printf "}")
)

(define j (synthesize-op '(BPF_ALU BPF_END BPF_FROM_BE)))
(if j
  (printsol j)
  (displayln "no solution"))
