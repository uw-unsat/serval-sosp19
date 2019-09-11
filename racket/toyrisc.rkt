#lang rosette

; import serval functions with prefix "serval:"
(require
  serval/lib/unittest
  rackunit/text-ui
  (prefix-in serval:
    (combine-in serval/lib/core
                serval/spec/refinement
                serval/spec/ni)))

#| ToyRISC Interpreter |#

; cpu state: program counter and integer registers
(struct cpu (pc regs) #:mutable #:transparent)

; interpret a program from a given cpu state
(define (interpret c program)
  ; Use Serval's "split-pc" symbolic optimization
  (serval:split-pc (cpu pc) c
    ; fetch an instruction to execute
    (define insn (fetch c program))
    ; decode an instruction into (opcode, rd, rs, imm)
    (match insn
      [(list opcode rd rs imm)
          ; execute the instruction
          (execute c opcode rd rs imm)
          ; recursively interpret a program until "ret"
          (when (not (equal? opcode 'ret))
            (interpret c program))])))

; fetch an instruction based on the current pc
(define (fetch c program)
  (define pc (cpu-pc c))
  ; the behavior is undefined if pc is out-of-bounds
  (serval:bug-on (< pc 0))
  (serval:bug-on (>= pc (vector-length program)))
  ; return the instruction at program[pc]
  (vector-ref program pc))

; shortcut for getting the value of register rs
(define (cpu-reg c rs)
  (vector-ref (cpu-regs c) rs))

; shortcut for setting register rd to value v
(define (set-cpu-reg! c rd v)
  (vector-set! (cpu-regs c) rd v))

; execute one instruction
(define (execute c opcode rd rs imm)
  (define pc (cpu-pc c))
  (case opcode
    [(ret)  ; return
       (set-cpu-pc! c 0)]
    [(bnez) ; branch to imm if rs is nonzero
       (if (! (= (cpu-reg c rs) 0))
           (set-cpu-pc! c imm)
           (set-cpu-pc! c (+ 1 pc)))]
    [(sgtz) ; set rd to 1 if rs > 0, 0 otherwise
       (set-cpu-pc! c (+ 1 pc))
       (if (> (cpu-reg c rs) 0)
         (set-cpu-reg! c rd 1)
         (set-cpu-reg! c rd 0))]
    [(sltz) ; set rd to 1 if rs < 0, 0 otherwise
       (set-cpu-pc! c (+ 1 pc))
       (if (< (cpu-reg c rs) 0)
         (set-cpu-reg! c rd 1)
         (set-cpu-reg! c rd 0))]
    [(li)   ; load imm into rd
       (set-cpu-pc! c (+ 1 pc))
       (set-cpu-reg! c rd imm)]))

#|
  Sign implementation
|#


#|
0: sltz a1, a0   ; a1 <- if (a0 < 0) then 1 else 0
1: bnez a1, 4    ; branch to 4 if a1 is nonzero
2: sgtz a0, a0   ; a0 <- if (a0 > 0) then 1 else 0
3: ret           ; return
4: li   a0, -1   ; a0 <- -1
5: ret           ; return
|#

(define sign-implementation #(
 (sltz 1 0 #f)
 (bnez #f 1 4)
 (sgtz 0 0 #f)
 (ret #f #f #f)
 (li 0 #f -1)
 (ret #f #f #f)
))

#|
  Sign specification
|#

; Note that we mark the struct as mutable and transparent
; for better debugging and interoperability with Serval libraries
(struct state (a0 a1) #:mutable #:transparent) ; specification state

; functional specification for the sign code
(define (spec-sign s)
  (define a0 (state-a0 s))
  (define sign (cond
    [(positive? a0)  1]
    [(negative? a0) -1]
    [else            0]))
  (define scratch (if (negative? a0) 1 0))
  (state sign scratch))

; abstraction function: impl. cpu state to spec. state
(define (AF c)
  (state (cpu-reg c 0) (cpu-reg c 1)))

; Mutable version of sign specification
(define (spec-sign-update s)
  (let ([s2 (spec-sign s)])
    (set-state-a0! s (state-a0 s2))
    (set-state-a1! s (state-a1 s2))))

#| State-machine refinement |#

; Fresh implementation state
(define-symbolic X Y integer?)
(define c (cpu 0 (vector X Y)))

; Fresh specification state
(define-symbolic a0 a1 integer?)
(define s (state a0 a1))

; Counterexample handler for debugging
(define (handle-counterexample sol)
  (printf "Verification failed:\n")
  (printf "Initial implementation state: ~a\n" (evaluate (cpu 0 (vector X Y)) sol))
  (printf "Initial specification state: ~a\n" (evaluate (state a0 a1) sol))
  (printf "Final implementation state ~a\n" (evaluate c sol))
  (printf "Final specification state ~a\n" (evaluate s sol)))

; Verify refinement
(define (verify-refinement)
  (serval:verify-refinement
  #:implstate c
  #:impl (λ (c) (interpret c sign-implementation))
  #:specstate s
  #:spec spec-sign-update
  #:abs AF
  #:ri (const #t)
  null
  handle-counterexample))

#| Safety property |#

(define (~ s1 s2)
  (equal? (state-a0 s1) (state-a0 s2))) ; filter out a1

(define (verify-safety)
  (serval:check-step-consistency
    #:state-init (λ () (define-symbolic* X Y integer?) (state X Y))
    #:state-copy (λ (s) (struct-copy state s))
    #:unwinding ~
    spec-sign-update))

(run-tests (test-suite+ "ToyRISC tests"
  (test-case+ "ToyRISC Refinement" (verify-refinement))
  (test-case+ "ToyRISC Safety" (verify-safety))))