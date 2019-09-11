#lang rosette

; https://bugs.chromium.org/p/project-zero/issues/detail?id=1496
; CVE-2017-17863

(require
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  serval/bpf
  serval/lib/unittest)


(define insns (make-insns
  ; zero register
  (BPF_MOV64_IMM BPF_REG_2 0)

  ; copy fp
  (BPF_MOV64_REG BPF_REG_1 BPF_REG_10)
  ; adjust fp up maximally (0x7fff'ffff),
  ; resulting in an sp
  (BPF_ALU64_IMM BPF_ADD BPF_REG_1 #x7fffffff)
  ; ... and now, thanks to 7bca0a9702edf, we get
  ; to do that again! this will wrap to negative
  ; in the verifier.
  (BPF_ALU64_IMM BPF_ADD BPF_REG_1 #x7fffffff)
  ; now store some stuff 4GB out of bounds
  (BPF_STX_MEM BPF_B BPF_REG_1 BPF_REG_2 0)

  ; terminate to make the verifier happy
  (BPF_MOV32_IMM BPF_REG_0 0)
  (BPF_EXIT_INSN)))

(define (check-poc)
  (define cpu (init-cpu #f (vector)))
  (check-exn exn:fail? (lambda () (with-asserts (interpret-program cpu insns))))
  (check-equal? current-pc-debug 4))

(define bpf-tests
  (test-suite+ "Tests for PoC (Project Zero 1496)"
    (test-case+ "CVE-2017-17863" (check-poc))))

(module+ test
  (time (run-tests bpf-tests)))
