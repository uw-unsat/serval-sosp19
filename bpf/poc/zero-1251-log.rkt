#lang rosette

; https://bugs.chromium.org/p/project-zero/issues/detail?id=1251
; CVE-2017-9150

(require
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  serval/bpf
  serval/lib/unittest)

(define mapfd 1)

(define insns (make-insns
  (BPF_LD_MAP_FD BPF_REG_0 mapfd)
  ; add one more line to trigger this as our interpreter stores fds rather than map pointers
  (BPF_MOV64_REG BPF_REG_0 BPF_REG_10)
  (BPF_MOV64_IMM BPF_REG_0 0)
  (BPF_EXIT_INSN)))

(define (check-poc)
  (define fdtable (vector #f (make-array-map 8 1)))

  (define cpu (init-cpu #f fdtable))
  (bpf-verbose (open-output-string))
  (bpf-allow-leak-pointer #t)
  (check-equal? (interpret-program cpu insns) (bv 0 32))

  (define cpu2 (init-cpu #f fdtable))
  (bpf-verbose (open-output-string))
  (bpf-allow-leak-pointer #f)
  (check-exn exn:fail? (lambda () (with-asserts (interpret-program cpu2 insns))))
  (check-equal? current-pc-debug 2))

(define bpf-tests
  (test-suite+ "Tests for PoC (Project Zero 1251)"
    (test-case+ "CVE-2017-9150" (check-poc))))

(module+ test
  (time (run-tests bpf-tests)))
