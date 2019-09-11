#lang rosette

(require (prefix-in core: serval/lib/core)
         (prefix-in llvm: serval/llvm)
         serval/bpf)

(require "generated/bpf/kbpf.ll.rkt")

(define MAX_STACK_SIZE 512)

(define (make-symbols p0)
  (define p1 (+ p0 32))
  (define p2 (+ p1 96))
  (define p3 (+ p2 MAX_STACK_SIZE))
  (list (list p0 p1 'B 'ctx)
        (list p1 p2 'B 'regs)
        (list p2 p3 'B 'stack)))

(define globals (make-hash (list
  (cons 'ctx  (thunk (core:marray 32 (core:mcell 1))))
  (cons 'stack (thunk (core:marray 512 (core:mcell 1))))
  (cons 'regs (thunk (core:marray 12 (core:mcell 8)))))))

(define (make-prog n)
  (core:marray n
    (core:mstruct 8 (list
      (core:mfield 0 0 (core:mcell 1))
      (core:mfield 1 1 (core:mcell 1))
      (core:mfield 2 2 (core:mcell 2))
      (core:mfield 3 4 (core:mcell 4))))))

(define (decode code)
  (case code
    [(BPF_LD) BPF_LD]
    [(BPF_LDX) BPF_LDX]
    [(BPF_ST) BPF_ST]
    [(BPF_STX) BPF_STX]
    [(BPF_ALU) BPF_ALU]
    [(BPF_JMP) BPF_JMP]
    [(BPF_RET) BPF_RET]
    [(BPF_MISC) BPF_MISC]
    [(BPF_ALU64) BPF_ALU64]
    [(BPF_W) BPF_W]
    [(BPF_H) BPF_H]
    [(BPF_B) BPF_B]
    [(BPF_DW) BPF_DW]
    [(BPF_XADD) BPF_XADD]
    [(BPF_IMM) BPF_IMM]
    [(BPF_ABS) BPF_ABS]
    [(BPF_IND) BPF_IND]
    [(BPF_MEM) BPF_MEM]
    [(BPF_LEN) BPF_LEN]
    [(BPF_MSH) BPF_MSH]
    [(BPF_ADD) BPF_ADD]
    [(BPF_SUB) BPF_SUB]
    [(BPF_MUL) BPF_MUL]
    [(BPF_DIV) BPF_DIV]
    [(BPF_OR) BPF_OR]
    [(BPF_AND) BPF_AND]
    [(BPF_LSH) BPF_LSH]
    [(BPF_RSH) BPF_RSH]
    [(BPF_NEG) BPF_NEG]
    [(BPF_MOD) BPF_MOD]
    [(BPF_XOR) BPF_XOR]
    [(BPF_MOV) BPF_MOV]
    [(BPF_ARSH) BPF_ARSH]
    [(BPF_JA) BPF_JA]
    [(BPF_JEQ) BPF_JEQ]
    [(BPF_JGT) BPF_JGT]
    [(BPF_JGE) BPF_JGE]
    [(BPF_JSET) BPF_JSET]
    [(BPF_JNE) BPF_JNE]
    [(BPF_JSGT) BPF_JSGT]
    [(BPF_JSGE) BPF_JSGE]
    [(BPF_CALL) BPF_CALL]
    [(BPF_EXIT) BPF_EXIT]
    [(BPF_END) BPF_END]
    [(BPF_FROM_LE) BPF_FROM_LE]
    [(BPF_FROM_BE) BPF_FROM_BE]
    [(BPF_K) BPF_K]
    [(BPF_X) BPF_X]
    [else (displayln code)]))

(define (symbol->code code)
  (apply bvor (map core:bv8 (if (list? code) (map decode code) (list 0)))))

(define (insn-field n x)
  (if (bv? x) x (bv 0 n)))

(define (insn-op x)
  (bv (if (integer? x) x 0) 4))

(define (prog-update-one! prog i insn)
  (displayln (cons 'update insn))
  (core:mblock-istore! prog (symbol->code (insn-code insn)) (list i 0))
  (core:mblock-istore! prog (concat (insn-op (insn-src insn)) (insn-op (insn-dst insn))) (list i 1))
  (core:mblock-istore! prog (insn-field 16 (insn-off insn)) (list i 2))
  (core:mblock-istore! prog (insn-field 32 (insn-imm insn)) (list i 3)))

(define (prog-update! prog insns [i 0])
  (unless (null? insns)
    (prog-update-one! prog (bv i 64) (car insns))
    (prog-update! prog (cdr insns) (add1 i))))

(define insns (flatten (list
  (BPF_LD_IMM64 BPF_REG_0 3)
  (BPF_ALU32_IMM BPF_MOV BPF_REG_1 1)
  (BPF_ALU64_REG BPF_SUB BPF_REG_0 BPF_REG_1)
  (BPF_EXIT_INSN))))

(parameterize ([llvm:current-machine (llvm:make-machine (make-symbols #x80000000) globals)])
  (define prog (make-prog (length insns)))
  (prog-update! prog insns)
  (define result (@bpf_prog_run (core:pointer prog (bv 0 64))))
  (displayln (asserts))
  (displayln result))
