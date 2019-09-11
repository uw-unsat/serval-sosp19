#lang rosette

(require
  "common.rkt"
  rosette/lib/angelic
  serval/lib/unittest
  (prefix-in core: serval/lib/core)
  (prefix-in bpf: serval/bpf)
  (prefix-in x32: serval/x32))

(provide (all-defined-out))

(define SCRATCH_SIZE 96)
(define STACK_SIZE SCRATCH_SIZE)

(define (STACK_OFFSET k) k)

(define bpf2ia32_map (vector
  (cons (STACK_OFFSET 0) (STACK_OFFSET 4)) ; R0
  (cons (STACK_OFFSET 8) (STACK_OFFSET 12)) ; R1
  (cons (STACK_OFFSET 16) (STACK_OFFSET 20)) ; R2
  (cons (STACK_OFFSET 24) (STACK_OFFSET 28)) ; R3
  (cons (STACK_OFFSET 32) (STACK_OFFSET 36)) ; R4
  (cons (STACK_OFFSET 40) (STACK_OFFSET 44)) ; R5
  (cons (STACK_OFFSET 48) (STACK_OFFSET 52)) ; R6
  (cons (STACK_OFFSET 56) (STACK_OFFSET 60)) ; R7
  (cons (STACK_OFFSET 64) (STACK_OFFSET 68)) ; R8
  (cons (STACK_OFFSET 72) (STACK_OFFSET 76)) ; R9
  (cons (STACK_OFFSET 80) (STACK_OFFSET 84)) ; FP
))

(define (bpf2ia32 r)
  (vector-ref bpf2ia32_map r))

(define lo car)
(define hi cdr)

(define IA32_EAX 'eax)
(define IA32_ECX 'ecx)
(define IA32_EDX 'edx)
(define IA32_EBX 'ebx)
(define IA32_ESP 'esp)
(define IA32_EBP 'ebp)
(define IA32_ESI 'esi)
(define IA32_EDI 'edi)

; List of x86 cond jumps opcodes (. + s8)
; Add 0x10 (and an extra 0x0f) to generate far jumps (. + s32)
(define IA32_JB  '0x72)
(define IA32_JAE '0x73)
(define IA32_JE  '0x74)
(define IA32_JNE '0x75)
(define IA32_JBE '0x76)
(define IA32_JA  '0x77)
(define IA32_JL  '0x7C)
(define IA32_JGE '0x7D)
(define IA32_JLE '0x7E)
(define IA32_JG  '0x7F)

(define (STACK_VAR off) (bv off 8))

(define-syntax-rule (add_1reg mod+opcode r/m)
  (@add_1reg 'mod+opcode r/m))

(define-syntax-rule (add_2reg mod r/m reg)
  (@add_2reg 'mod r/m reg))

(define-syntax-rule (EMIT2 b1 b2 pprog)
  (@EMIT2 'b1 b2 pprog))

(define-syntax-rule (EMIT3 b1 b2 b3 pprog)
  (@EMIT3 'b1 b2 b3 pprog))

(define-syntax-rule (EMIT4 b1 b2 b3 b4 pprog)
  (@EMIT4 'b1 'b2 b3 b4 pprog))

(define-syntax-rule (EMIT2_off32 b1 b2 off pprog)
  (emit_code (decode (list 'b1 b2 off) 6) pprog))

(define-syntax-rule (EMIT3_off32 b1 b2 b3 off pprog)
  (emit_code (decode (list 'b1 b2 b3 off) 7) pprog))

(define (@add_1reg mod+opcode r/m)
  (x32:ModOpcodeR/M mod+opcode r/m))

(define (@add_2reg mod r/m reg)
  (x32:ModR/M mod r/m reg))

(define (@EMIT2 b1 b2 pprog)
  (emit_code (decode (list b1 b2) 2) pprog))

(define (@EMIT3 b1 b2 b3 pprog)
  (emit_code (decode (list b1 b2 b3) 3) pprog))

(define (@EMIT4 b1 b2 b3 b4 pprog)
  (emit_code (decode (list b1 b2 b3 b4) 4) pprog))

(define (emit_code insn ctx)
  (set-box! ctx (vector-append (unbox ctx) (vector insn))))

(define (decode code size)
  (define insn (x32:decode code))
  (core:bug-on (! (equal? code (x32:instruction-encode insn)))
   #:dbg code
   #:msg "instruction decode-encode mismatch!")
  (core:bug-on (! (equal? size (x32:instruction-size insn)))
   #:dbg code
   #:msg (format "instruction size mismatch: ~a" size))
  insn)

(define (is_imm8 imm32)
  (&& (bvsle imm32 (bv 127 32))
      (bvsge imm32 (bv -128 32))))

(define (is_imm32 imm64)
  (bveq imm64 (sign-extend ((extract 31 0) imm64) (bitvector 64))))

(define (emit_ia32_mov_i dst val dstk pprog)
  (cond
    [dstk
     (cond
       [(equal? val (bv 0 32))
        ; xor eax,eax
        (EMIT2 0x33 (add_2reg 0xC0 IA32_EAX IA32_EAX) pprog)
        ; mov dword ptr [ebp+off],eax
        (EMIT3 0x89 (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR dst) pprog)]
       [else
        (EMIT3_off32 0xC7 (add_1reg 0x40 IA32_EBP) (STACK_VAR dst) val pprog)])]
    [else
     (cond
       [(equal? val (bv 0 32))
        (EMIT2 0x33 (add_2reg 0xC0 dst dst) pprog)]
       [else
        (EMIT2_off32 0xC7 (add_1reg 0xC0 dst) val pprog)])]))


(define (emit_ia32_mov_r dst src dstk sstk pprog)
  (define sreg (if sstk IA32_EAX src))
  (when sstk
    ; mov eax,dword ptr [ebp+off]
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR src) pprog))
  (cond
    [dstk
     ; mov dword ptr [ebp+off],eax
     (EMIT3 0x89 (add_2reg 0x40 IA32_EBP sreg) (STACK_VAR dst) pprog)]
    [else
     ; mov dst,sreg
     (EMIT2 0x89 (add_2reg 0xC0 dst sreg) pprog)]))


(define (emit_ia32_mov_r64 is64 dst src dstk sstk pprog)
  (emit_ia32_mov_r (lo dst) (lo src) dstk sstk pprog)
  (cond
    [is64
     ; complete 8 byte move
     (emit_ia32_mov_r (hi dst) (hi src) dstk sstk pprog)]
    [else
     ; zero out high 4 bytes
     (emit_ia32_mov_i (hi dst) (bv 0 32) dstk pprog)]))


(define (emit_ia32_mov_i64 is64 dst val dstk pprog)
  (define hival (bv 0 32))
  (when (&& is64 (core:bitvector->bool (bvand val (bvshl (bv 1 32) (bv 31 32)))))
    (set! hival (bvnot (bv 0 32))))
  (emit_ia32_mov_i (lo dst) val dstk pprog)
  (emit_ia32_mov_i (hi dst) hival dstk pprog))


; dst = -dst (64 bit)
(define (emit_ia32_neg64 dst dstk pprog)
  (define dreg_lo (if dstk IA32_EAX (lo dst)))
  (define dreg_hi (if dstk IA32_EDX (hi dst)))

  (when dstk
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX)
           (STACK_VAR (lo dst)) pprog)
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX)
           (STACK_VAR (hi dst)) pprog))

  ; neg dreg_lo
  (EMIT2 0xF7 (add_1reg 0xD8 dreg_lo) pprog)
  ; adc dreg_hi,0x0
  (EMIT3 0x83 (add_1reg 0xD0 dreg_hi) (bv 0 8) pprog)
  ; neg dreg_hi
  (EMIT2 0xF7 (add_1reg 0xD8 dreg_hi) pprog)

  (when dstk
    ; mov dword ptr [ebp+off],dreg_lo
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_lo)
           (STACK_VAR (lo dst)) pprog)
    ; mov dword ptr [ebp+off],dreg_hi
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_hi)
           (STACK_VAR (hi dst)) pprog)))


; dst = dst << src
(define (emit_ia32_lsh_r64 dst src dstk sstk pprog)
  (define dreg_lo (if dstk IA32_EAX (lo dst)))
  (define dreg_hi (if dstk IA32_EDX (hi dst)))

  (when dstk
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX)
           (STACK_VAR (lo dst)) pprog)
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX)
           (STACK_VAR (hi dst)) pprog))

  (cond
    [sstk
     ; mov ecx,dword ptr [ebp+off]
     (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_ECX) (STACK_VAR (lo src)) pprog)]
    [else
     ; mov ecx,src_lo
     (EMIT2 0x8B (add_2reg 0xC0 (lo src) IA32_ECX) pprog)])

  ; shld dreg_hi,dreg_lo,cl
  (@EMIT3 '0x0F '0xA5 (add_2reg 0xC0 dreg_hi dreg_lo) pprog)
  ; shl dreg_lo,cl
  (EMIT2 0xD3 (add_1reg 0xE0 dreg_lo) pprog)

  ; if ecx >= 32, mov dreg_lo into dreg_hi and clear dreg_lo

  ; cmp ecx,32
  (EMIT3 0x83 (add_1reg 0xF8 IA32_ECX) (bv 32 8) pprog)
  ; skip the next two instructions (4 bytes) when < 32
  (@EMIT2 IA32_JB (bv 4 8) pprog)

  ; mov dreg_hi,dreg_lo
  (EMIT2 0x89 (add_2reg 0xC0 dreg_hi dreg_lo) pprog)
  ; xor dreg_lo,dreg_lo
  (EMIT2 0x33 (add_2reg 0xC0 dreg_lo dreg_lo) pprog)

  (when dstk
    ; mov dword ptr [ebp+off],dreg_lo
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_lo)
           (STACK_VAR (lo dst)) pprog)
    ; mov dword ptr [ebp+off],dreg_hi
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_hi)
           (STACK_VAR (hi dst)) pprog)))


; dst = dst >> src
(define (emit_ia32_rsh_r64 dst src dstk sstk pprog)
  (define dreg_lo (if dstk IA32_EAX (lo dst)))
  (define dreg_hi (if dstk IA32_EDX (hi dst)))

  (when dstk
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX)
           (STACK_VAR (lo dst)) pprog)
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX)
           (STACK_VAR (hi dst)) pprog))

  (cond
    [sstk
     ; mov ecx,dword ptr [ebp+off]
     (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_ECX) (STACK_VAR (lo src)) pprog)]
    [else
     ; mov ecx,src_lo
     (EMIT2 0x8B (add_2reg 0xC0 (lo src) IA32_ECX) pprog)])

  ; shrd dreg_lo,dreg_hi,cl
  (@EMIT3 '0x0F '0xAD (add_2reg 0xC0 dreg_lo dreg_hi) pprog)
  ; shr dreg_hi,cl
  (EMIT2 0xD3 (add_1reg 0xE8 dreg_hi) pprog)

  ; if ecx >= 32, mov dreg_hi to dreg_lo and clear dreg_hi

  ; cmp ecx,32
  (EMIT3 0x83 (add_1reg 0xF8 IA32_ECX) (bv 32 8) pprog)
  ; skip the next two instructions (4 bytes) when < 32
  (@EMIT2 IA32_JB (bv 4 8) pprog)

  ; mov dreg_lo,dreg_hi
  (EMIT2 0x89 (add_2reg 0xC0 dreg_lo dreg_hi) pprog)
  ; xor dreg_hi,dreg_hi
  (EMIT2 0x33 (add_2reg 0xC0 dreg_hi dreg_hi) pprog)

  (when dstk
    ; mov dword ptr [ebp+off],dreg_lo
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_lo)
           (STACK_VAR (lo dst)) pprog)
    ; mov dword ptr [ebp+off],dreg_hi
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_hi)
           (STACK_VAR (hi dst)) pprog)))


; dst = dst >> src (signed)
(define (emit_ia32_arsh_r64 dst src dstk sstk pprog)
  (define dreg_lo (if dstk IA32_EAX (lo dst)))
  (define dreg_hi (if dstk IA32_EDX (hi dst)))

  (when dstk
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX)
           (STACK_VAR (lo dst)) pprog)
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX)
           (STACK_VAR (hi dst)) pprog))

  (cond
    [sstk
     ; mov ecx,dword ptr [ebp+off]
     (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_ECX) (STACK_VAR (lo src)) pprog)]
    [else
     ; mov ecx,src_lo
     (EMIT2 0x8B (add_2reg 0xC0 (lo src) IA32_ECX) pprog)])

  ; shrd dreg_lo,dreg_hi,cl
  (@EMIT3 '0x0F '0xAD (add_2reg 0xC0 dreg_lo dreg_hi) pprog)
  ; sar dreg_hi,cl
  (EMIT2 0xD3 (add_1reg 0xF8 dreg_hi) pprog)

  ; if ecx >= 32, mov dreg_hi to dreg_lo and set/clear dreg_hi
  ; depending on the sign

  ; cmp ecx,32
  (EMIT3 0x83 (add_1reg 0xF8 IA32_ECX) (bv 32 8) pprog)
  ; skip the next two instructions (5 bytes) when < 32
  (@EMIT2 IA32_JB (bv 5 8) pprog)

  ; mov dreg_lo,dreg_hi
  (EMIT2 0x89 (add_2reg 0xC0 dreg_lo dreg_hi) pprog)
  ; sar dreg_hi,31
  (EMIT3 0xC1 (add_1reg 0xF8 dreg_hi) (bv 31 8) pprog)

  (when dstk
    ; mov dword ptr [ebp+off],dreg_lo
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_lo)
           (STACK_VAR (lo dst)) pprog)
    ; mov dword ptr [ebp+off],dreg_hi
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_hi)
           (STACK_VAR (hi dst)) pprog)))


; dst = dst << val
(define (emit_ia32_lsh_i64 dst val dstk pprog)
  (define dreg_lo (if dstk IA32_EAX (lo dst)))
  (define dreg_hi (if dstk IA32_EDX (hi dst)))

  (when dstk
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX)
           (STACK_VAR (lo dst)) pprog)
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX)
           (STACK_VAR (hi dst)) pprog))

  (cond
    [(bvult val (bv 32 32))
     ; PATCH: the old code is unnecessarily complicated and
     ; incorrect when val == 0.

     ; shld dreg_hi,dreg_lo,imm8
     (EMIT4 0x0F 0xA4 (add_2reg 0xC0 dreg_hi dreg_lo) (extract 7 0 val) pprog)
     ; shl dreg_lo,imm8
     (EMIT3 0xC1 (add_1reg 0xE0 dreg_lo) (extract 7 0 val) pprog)]

    ;  ; shl dreg_hi,imm8
    ;  (EMIT3 0xC1 (add_1reg 0xE0 dreg_hi) val pprog)
    ;  ; mov ebx,dreg_lo
    ;  (EMIT2 0x8B (add_2reg 0xC0 dreg_lo IA32_EBX) pprog)
    ;  ; shl dreg_lo,imm8
    ;  (EMIT3 0xC1 (add_1reg 0xE0 dreg_lo) val pprog)

    ;  ; IA32_ECX = 32 - val
    ;  ; mov ecx,val
    ;  (EMIT2 0xB1 val pprog)
    ;  ; movzx ecx,ecx
    ;  (@EMIT3 0x0F 0xB6 (add_2reg 0xC0 IA32_ECX IA32_ECX) pprog)
    ;  ; neg ecx
    ;  (EMIT2 0xF7 (add_1reg 0xD8 IA32_ECX) pprog)
    ;  ; add ecx,32
    ;  (EMIT3 0x83 (add_1reg 0xC0 IA32_ECX) (bv 32 32) pprog)

    ;  ; shr ebx,cl
    ;  (EMIT2 0xD3 (add_1reg 0xE8 IA32_EBX) pprog)
    ;  ; or dreg_hi,ebx
    ;  (EMIT2 0x09 (add_2reg 0xC0 dreg_hi IA32_EBX) pprog)]
    [else
     (define value (bvsub val (bv 32 32)))

     ; shl dreg_lo,imm8
     (EMIT3 0xC1 (add_1reg 0xE0 dreg_lo) (extract 7 0 value) pprog)
     ; mov dreg_hi,dreg_lo
     (EMIT2 0x89 (add_2reg 0xC0 dreg_hi dreg_lo) pprog)
     ; xor dreg_lo,dreg_lo
     (EMIT2 0x33 (add_2reg 0xC0 dreg_lo dreg_lo) pprog)])

  (when dstk
    ; mov dword ptr [ebp+off],dreg_lo
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_lo)
           (STACK_VAR (lo dst)) pprog)
    ; mov dword ptr [ebp+off],dreg_hi
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_hi)
           (STACK_VAR (hi dst)) pprog)))


; dst = dst >> val
(define (emit_ia32_rsh_i64 dst val dstk pprog)
  (define dreg_lo (if dstk IA32_EAX (lo dst)))
  (define dreg_hi (if dstk IA32_EDX (hi dst)))

  (when dstk
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX)
           (STACK_VAR (lo dst)) pprog)
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX)
           (STACK_VAR (hi dst)) pprog))

  (cond
    [(bvult val (bv 32 32))
     ; PATCH: the old code is unnecessarily complicated and
     ; incorrect when val == 0.

     ; shrd dreg_lo,dreg_hi,imm8
     (EMIT4 0x0F 0xAC (add_2reg 0xC0 dreg_lo dreg_hi) (extract 7 0 val) pprog)
     ; shr dreg_hi,imm8
     (EMIT3 0xC1 (add_1reg 0xE8 dreg_hi) (extract 7 0 val) pprog)]
    [else
     (define value (bvsub val (bv 32 32)))

     ; shr dreg_hi,imm8
     (EMIT3 0xC1 (add_1reg 0xE8 dreg_hi) (extract 7 0 value) pprog)
     ; mov dreg_lo,dreg_hi
     (EMIT2 0x89 (add_2reg 0xC0 dreg_lo dreg_hi) pprog)
     ; xor dreg_hi,dreg_hi
     (EMIT2 0x33 (add_2reg 0xC0 dreg_hi dreg_hi) pprog)])

  (when dstk
    ; mov dword ptr [ebp+off],dreg_lo
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_lo)
           (STACK_VAR (lo dst)) pprog)
    ; mov dword ptr [ebp+off],dreg_hi
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_hi)
           (STACK_VAR (hi dst)) pprog)))


; dst = dst >> val (signed)
(define (emit_ia32_arsh_i64 dst val dstk pprog)
  (define dreg_lo (if dstk IA32_EAX (lo dst)))
  (define dreg_hi (if dstk IA32_EDX (hi dst)))

  (when dstk
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX)
           (STACK_VAR (lo dst)) pprog)
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX)
           (STACK_VAR (hi dst)) pprog))

  (cond
    [(bvult val (bv 32 32))
     ; PATCH: the old code is unnecessarily complicated and
     ; incorrect when val == 0.

     ; shrd dreg_lo,dreg_hi,imm8
     (EMIT4 0x0F 0xAC (add_2reg 0xC0 dreg_lo dreg_hi) (extract 7 0 val) pprog)
     ; sar dreg_hi,imm8
     (EMIT3 0xC1 (add_1reg 0xF8 dreg_hi) (extract 7 0 val) pprog)]
    [else
     (define value (bvsub val (bv 32 32)))

     ; sar dreg_hi,imm8
     (EMIT3 0xC1 (add_1reg 0xF8 dreg_hi) (extract 7 0 value) pprog)
     ; mov dreg_lo,dreg_hi
     (EMIT2 0x89 (add_2reg 0xC0 dreg_lo dreg_hi) pprog)
     ; sar dreg_hi,imm8
     (EMIT3 0xC1 (add_1reg 0xF8 dreg_hi) (bv 31 8) pprog)])

  (when dstk
    ; mov dword ptr [ebp+off],dreg_lo
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_lo)
           (STACK_VAR (lo dst)) pprog)
    ; mov dword ptr [ebp+off],dreg_hi
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg_hi)
           (STACK_VAR (hi dst)) pprog)))


(define (emit_ia32_shift_r op dst src dstk sstk pprog)
  (define dreg (if dstk IA32_EAX dst))
  (when dstk
    ; mov eax,dword ptr [ebp+off]
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR dst) pprog))
  (cond
   [sstk
    ; mov ecx,dword ptr [ebp+off]
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_ECX) (STACK_VAR src) pprog)]
   [(! (equal? src IA32_ECX))
    ; mov ecx,src
    (EMIT2 0x8B (add_2reg 0xC0 src IA32_ECX) pprog)])
  (define b2
    (case op
      [(BPF_LSH) '0xE0]
      [(BPF_RSH) '0xE8]
      [(BPF_ARSH) '0xF8]))
  (EMIT2 0xD3 (@add_1reg b2 dreg) pprog)

  (when dstk
    ; mov dword ptr [ebp+off],dreg
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg) (STACK_VAR dst) pprog)))


(define (emit_ia32_alu_r is64 hi? op dst src dstk sstk pprog)
  (define sreg (if sstk IA32_EAX src))
  (define dreg (if dstk IA32_EDX dst))

  (when sstk
    ; mov eax,dword ptr [ebp+off]
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR src) pprog))
  (when dstk
    ; mov eax,dword ptr [ebp+off]
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EDX) (STACK_VAR dst) pprog))

  (case op
    [(BPF_ADD)
     (cond
       [(&& hi? is64)
        (EMIT2 0x11 (add_2reg 0xC0 dreg sreg) pprog)]
       [else
        (EMIT2 0x01 (add_2reg 0xC0 dreg sreg) pprog)])]
    [(BPF_SUB)
     (cond
       [(&& hi? is64)
        (EMIT2 0x19 (add_2reg 0xC0 dreg sreg) pprog)]
       [else
        (EMIT2 0x29 (add_2reg 0xC0 dreg sreg) pprog)])]
    [(BPF_OR)
     (EMIT2 0x09 (add_2reg 0xC0 dreg sreg) pprog)]
    [(BPF_AND)
     (EMIT2 0x21 (add_2reg 0xC0 dreg sreg) pprog)]
    [(BPF_XOR)
     (EMIT2 0x31 (add_2reg 0xC0 dreg sreg) pprog)])

  (when dstk
    ; mov dword ptr [ebp+off],dreg
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg) (STACK_VAR dst) pprog)))


(define (emit_ia32_alu_r64 is64 op dst src dstk sstk pprog)
  (emit_ia32_alu_r is64 #f op (lo dst) (lo src) dstk sstk pprog)
  (cond
    [is64
     (emit_ia32_alu_r is64 #t op (hi dst) (hi src) dstk sstk pprog)]
    [else
     (emit_ia32_mov_i (hi dst) (bv 0 32) dstk pprog)]))


(define (emit_ia32_alu_i is64 hi? op dst val dstk pprog)
  (define dreg (if dstk IA32_EAX dst))
  (define sreg IA32_EDX)

  (when dstk
    ; mov eax,dword ptr [ebp+off]
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR dst) pprog))
  (when (! (is_imm8 val))
    ; mov edx,imm32
    (EMIT2_off32 0xC7 (add_1reg 0xC0 IA32_EDX) val pprog))

  (case op
    [(BPF_ADD)
     (if (&& hi? is64)
         (if (is_imm8 val)
             (EMIT3 0x83 (add_1reg 0xD0 dreg) (extract 7 0 val) pprog)
             (EMIT2 0x11 (add_2reg 0xC0 dreg sreg) pprog))
         (if (is_imm8 val)
             (EMIT3 0x83 (add_1reg 0xC0 dreg) (extract 7 0 val) pprog)
             (EMIT2 0x01 (add_2reg 0xC0 dreg sreg) pprog)))]
    [(BPF_SUB)
     (if (&& hi? is64)
         (if (is_imm8 val)
             (EMIT3 0x83 (add_1reg 0xD8 dreg) (extract 7 0 val) pprog)
             (EMIT2 0x19 (add_2reg 0xC0 dreg sreg) pprog))
         (if (is_imm8 val)
             (EMIT3 0x83 (add_1reg 0xE8 dreg) (extract 7 0 val) pprog)
             (EMIT2 0x29 (add_2reg 0xC0 dreg sreg) pprog)))]
    [(BPF_AND)
     (if (is_imm8 val)
         (EMIT3 0x83 (add_1reg 0xE0 dreg) (extract 7 0 val) pprog)
         (EMIT2 0x21 (add_2reg 0xC0 dreg sreg) pprog))]
    [(BPF_OR)
     (if (is_imm8 val)
         (EMIT3 0x83 (add_1reg 0xC8 dreg) (extract 7 0 val) pprog)
         (EMIT2 0x09 (add_2reg 0xC0 dreg sreg) pprog))]
    [(BPF_XOR)
     (if (is_imm8 val)
         (EMIT3 0x83 (add_1reg 0xF0 dreg) (extract 7 0 val) pprog)
         (EMIT2 0x31 (add_2reg 0xC0 dreg sreg) pprog))]
    [(BPF_NEG)
     (EMIT2 0xF7 (add_1reg 0xD8 dreg) pprog)])

  (when dstk
    ; mov dword ptr [ebp+off],dreg
    (EMIT3 0x89 (add_2reg 0x40 IA32_EBP dreg) (STACK_VAR dst) pprog)))


(define (emit_ia32_alu_i64 is64 op dst val dstk pprog)
  (define hival (bv 0 32))
  (when (&& is64 (! (core:bvzero? (bvand val (bv (arithmetic-shift 1 31) 32)))))
    (set! hival (bv -1 32)))

  (emit_ia32_alu_i is64 #f op (lo dst) val dstk pprog)
  (if is64
      (emit_ia32_alu_i is64 #t op (hi dst) hival dstk pprog)
      (emit_ia32_mov_i (hi dst) (bv 0 32) dstk pprog)))


(define (emit_ia32_mul_r dst src dstk sstk pprog)
  (define sreg (if sstk IA32_ECX src))

  (when sstk
    ; mov ecx,dword ptr [ebp+off]
    (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_ECX) (STACK_VAR src) pprog))

  (if dstk
      ; mov eax,dword ptr [ebp+off]
      (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR dst) pprog)
      ; mov eax,dst
      (EMIT2 0x8B (add_2reg 0xC0 dst IA32_EAX) pprog))

  ; mul sreg
  (EMIT2 0xF7 (add_1reg 0xE0 sreg) pprog)

  (if dstk
      ; mov dword ptr [ebp+off],eax
      (EMIT3 0x89 (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR dst) pprog)
      ; mov dst,eax
      (EMIT2 0x89 (add_2reg 0xC0 dst IA32_EAX) pprog)))


(define (emit_ia32_mul_r64 dst src dstk sstk pprog)
  (if dstk
      ; mov eax,dword ptr [ebp+off]
      (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR (hi dst)) pprog)
      ; mov eax,dst_hi
      (EMIT2 0x8B (add_2reg 0xC0 (hi dst) IA32_EAX) pprog))

  (if sstk
      ; mul dword ptr [ebp+off]
      (EMIT3 0xF7 (add_1reg 0x60 IA32_EBP) (STACK_VAR (lo src)) pprog)
      ; mul src_lo
      (EMIT2 0xF7 (add_1reg 0xE0 (lo src)) pprog))

  ; mov ecx,eax
  (EMIT2 0x89 (add_2reg 0xC0 IA32_ECX IA32_EAX) pprog)

  (if dstk
      ; mov eax,dword ptr [ebp+off]
      (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR (lo dst)) pprog)
      ; mov eax,dst_lo
      (EMIT2 0x8B (add_2reg 0xC0 (lo dst) IA32_EAX) pprog))

  (if sstk
      ; mul dword ptr [ebp+off]
      (EMIT3 0xF7 (add_1reg 0x60 IA32_EBP) (STACK_VAR (hi src)) pprog)
      ; mul src_hi
      (EMIT2 0xF7 (add_1reg 0xE0 (hi src)) pprog))

  ; add ecx,eax
  (EMIT2 0x01 (add_2reg 0xC0 IA32_ECX IA32_EAX) pprog)

  (if dstk
      ; mov eax,dword ptr [ebp+off]
      (EMIT3 0x8B (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR (lo dst)) pprog)
      ; mov eax,dst_lo
      (EMIT2 0x8B (add_2reg 0xC0 (lo dst) IA32_EAX) pprog))

  (if sstk
      ; mul dword ptr [ebp+off]
      (EMIT3 0xF7 (add_1reg 0x60 IA32_EBP) (STACK_VAR (lo src)) pprog)
      ; mul src_lo
      (EMIT2 0xF7 (add_1reg 0xE0 (lo src)) pprog))

  ; add ecx,edx
  (EMIT2 0x01 (add_2reg 0xC0 IA32_ECX IA32_EDX) pprog)

  (cond
    [dstk
     ; mov dword ptr [ebp+off],eax
     (EMIT3 0x89 (add_2reg 0x40 IA32_EBP IA32_EAX) (STACK_VAR (lo dst)) pprog)
     ; mov dword ptr [ebp+off],ecx
     (EMIT3 0x89 (add_2reg 0x40 IA32_EBP IA32_ECX) (STACK_VAR (hi dst)) pprog)]
     [else
      ; mov dst_lo,eax
      (EMIT2 0x89 (add_2reg 0xC0 (lo dst) IA32_EAX) pprog)
      ; mov dst_hi,ecx
      (EMIT2 0x89 (add_2reg 0xC0 (hi dst) IA32_ECX) pprog)]))


(define BPF_CLASS first)
(define BPF_OP second)
(define BPF_SRC last)

(define (run-jit code dst_reg src_reg off imm32)
  (define &prog (box #()))

  (define is64 (equal? (BPF_CLASS code) 'BPF_ALU64))
  (define dstk #t)
  (define sstk #t)
  (define dst (if dst_reg (bpf2ia32 dst_reg) #f))
  (define src (if src_reg (bpf2ia32 src_reg) #f))

  (match code
    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_MOV 'BPF_X)
     (emit_ia32_mov_r64 is64 dst src dstk sstk &prog)]

    [(list (or 'BPF_ALU 'BPF_ALU64) 'BPF_MOV 'BPF_K)
     (emit_ia32_mov_i64 is64 dst imm32 dstk &prog)]

    [(list (or 'BPF_ALU 'BPF_ALU64) (or 'BPF_ADD 'BPF_SUB 'BPF_OR 'BPF_AND 'BPF_XOR) 'BPF_X)
     (emit_ia32_alu_r64 is64 (BPF_OP code) dst src dstk sstk &prog)]

    [(list (or 'BPF_ALU 'BPF_ALU64) (or 'BPF_ADD 'BPF_SUB 'BPF_OR 'BPF_AND 'BPF_XOR) 'BPF_K)
     (emit_ia32_alu_i64 is64 (BPF_OP code) dst imm32 dstk &prog)]

    [(list 'BPF_ALU (or 'BPF_LSH 'BPF_RSH 'BPF_ARSH) 'BPF_X)
     (emit_ia32_shift_r (BPF_OP code) (lo dst) (lo src) dstk sstk &prog)
     (emit_ia32_mov_i (hi dst) (bv 0 32) dstk &prog)]

    [(list 'BPF_ALU (or 'BPF_LSH 'BPF_RSH 'BPF_ARSH) 'BPF_K)
     ; mov ecx,imm32
     (EMIT2_off32 0xC7 (add_1reg 0xC0 IA32_ECX) imm32 &prog)
     (emit_ia32_shift_r (BPF_OP code) (lo dst) IA32_ECX dstk #f &prog)
     (emit_ia32_mov_i (hi dst) (bv 0 32) dstk &prog)]

    [(list 'BPF_ALU 'BPF_MUL 'BPF_X)
     (emit_ia32_mul_r (lo dst) (lo src) dstk sstk &prog)
     (emit_ia32_mov_i (hi dst) (bv 0 32) dstk &prog)]
    [(list 'BPF_ALU 'BPF_MUL 'BPF_K)
     ; mov ecx,imm32
     (EMIT2_off32 0xC7 (add_1reg 0xC0 IA32_ECX) imm32 &prog)
     (emit_ia32_mul_r (lo dst) IA32_ECX dstk #f &prog)
     (emit_ia32_mov_i (hi dst) (bv 0 32) dstk &prog)]

    ; dst = dst << imm
    [(list 'BPF_ALU64 'BPF_LSH 'BPF_K)
     (emit_ia32_lsh_i64 dst imm32 dstk &prog)]
    ; dst = dst >> imm
    [(list 'BPF_ALU64 'BPF_RSH 'BPF_K)
     (emit_ia32_rsh_i64 dst imm32 dstk &prog)]
    ; dst = dst >> imm (signed)
    [(list 'BPF_ALU64 'BPF_ARSH 'BPF_K)
     (emit_ia32_arsh_i64 dst imm32 dstk &prog)]

    ; dst = dst << src
    [(list 'BPF_ALU64 'BPF_LSH 'BPF_X)
     (emit_ia32_lsh_r64 dst src dstk sstk &prog)]
    ; dst = dst >> src
    [(list 'BPF_ALU64 'BPF_RSH 'BPF_X)
     (emit_ia32_rsh_r64 dst src dstk sstk &prog)]
    ; dst = dst >> src (signed)
    [(list 'BPF_ALU64 'BPF_ARSH 'BPF_X)
     (emit_ia32_arsh_r64 dst src dstk sstk &prog)]

    ; dst = -dst
    [(list 'BPF_ALU 'BPF_NEG)
     (emit_ia32_alu_i is64 #f (BPF_OP code) (lo dst) (bv 0 32) dstk &prog)
     (emit_ia32_mov_i (hi dst) (bv 0 32) dstk &prog)]
    [(list 'BPF_ALU64 'BPF_NEG)
     (emit_ia32_neg64 dst dstk &prog)]

    [(list 'BPF_ALU64 'BPF_MUL 'BPF_X)
     (emit_ia32_mul_r64 dst src dstk sstk &prog)]
    ; [(list 'BPF_ALU64 'BPF_MUL 'BPF_K)
    ;  (emit_ia32_mul_i64 dst imm32 dstk &prog)]
  )

  (unbox &prog))


; BPF registers
(define-symbolic pc r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 (bitvector 64))
(define bpf-regs (vector r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10))

(define (x32->bpf-regs x32)
  (define stack-block (core:find-block-by-name (x32:cpu-mregions x32) 'stack))
  (for/vector [(i (in-range (vector-length bpf-regs)))]
    (define loval
      (core:mblock-iload stack-block (list (bv (/ (lo (bpf2ia32 i)) 4) 32))))
    (define hival
      (core:mblock-iload stack-block (list (bv (/ (hi (bpf2ia32 i)) 4) 32))))
    (concat hival loval)))

(define (cpu-equal? bpf x32)
  (equal? (bpf:cpu-regs bpf) (x32->bpf-regs x32)))

(define (make-x32-program base instrs)
  (define current base)
  (define term (x32:ret))
  (define code
    (for/hash ([i (append instrs (list term))])
      (define addr current)
      (set! current (bvadd current (bv (x32:instruction-size i) 32)))
      (values addr i)))
  (x32:program base code))

(define (init-x32-cpu bpf-cpu)
  (define globals (make-hash (list (cons 'stack (thunk (core:marray (/ STACK_SIZE 4) (core:mcell 4)))))))
  (define stack-base #x1000)
  (define stack-top (+ stack-base STACK_SIZE))
  (define symbols `((,stack-base ,stack-top B stack)))

  (define x32-cpu (x32:init-cpu symbols globals))

  ; be lazy & simple
  (x32:gpr-set! x32-cpu 'ebp (bv stack-base 32))

  (define stack-block (core:find-block-by-name (x32:cpu-mregions x32-cpu) 'stack))

  (for ([i (in-range (vector-length bpf-regs))]
        [v (bpf:cpu-regs bpf-cpu)])
    (define loreg (lo (bpf2ia32 i)))
    (define loval (extract 31 0 v))
    (define hireg (hi (bpf2ia32 i)))
    (define hival (extract 63 32 v))
    (if (integer? loreg)
      (core:mblock-istore! stack-block loval (list (bv (/ loreg 4) 32)))
      (x32:gpr-set! x32-cpu loreg loval))
    (if (integer? hireg)
      (core:mblock-istore! stack-block hival (list (bv (/ hireg 4) 32)))
      (x32:gpr-set! x32-cpu hireg hival)))

  x32-cpu)

(define (run-jitted-code x32-cpu insns)
  (define base (bv #x400000 32))
  (x32:set-cpu-pc! x32-cpu base)
  (for/all ([insns insns #:exhaustive]) (begin
    ; (for ([i insns]) (displayln i))
    (define x32-program (make-x32-program base (vector->list insns)))
    (x32:interpret-program x32-cpu x32-program))))

(define (check-jit code #:verify? [verify? #t])
  (parameterize
    ([core:target-pointer-bitwidth 32])
      (verify-jit-refinement
        code
        #:init-cpu init-x32-cpu
        #:equiv cpu-equal?
        #:run-jit run-jit
        #:run-code run-jitted-code
        #:verify? verify?)))

(define-syntax-rule (jit-test-case code)
  (test-case+ (format "~s" code) (check-jit code)))

(define-syntax-rule (jit-quickcheck-case code)
  (test-case+ (format "~s" code) (quickcheck (check-jit code #:verify? #f))))
