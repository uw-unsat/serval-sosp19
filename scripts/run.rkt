#lang racket

(require racket/cmdline)

(define verify-on (make-parameter #f))
(define run-on (make-parameter #f))
(define system-name (make-parameter #f))
(define tests-on (make-parameter #f))
(define tables-on (make-parameter #f))
(define optimization-level (make-parameter 2))
(define use-spike (make-parameter #f))
(define bpf-on (make-parameter #f))
(define disable-split-pc (make-parameter #f))

(define system (command-line
 #:program "run"
 #:once-any
 [("--verify") system "Verify a system"
               (verify-on #t) (system-name system)]
 [("--run") system "Run a system"
            (run-on #t) (system-name system)]
 [("--run-tests") "Run serval tests"
                  (tests-on #t)]
 [("--tables") "Generate data used in tables"
            (tables-on #t)]
 [("--bpf") "Run BPF JIT verification"
            (bpf-on #t)]
 #:once-any
 [("--opt-0") "Optimization level 0"
          (optimization-level 0)]
 [("--opt-1") "Optimization level 1"
          (optimization-level 1)]
 [("--opt-2") "Optimization level 2"
          (optimization-level 2)]
 #:once-each
 [("--spike") "Use Spike to test instead of QEMU"
              (use-spike #t)]
 [("--disable-split-pc") "Disable split-pc symbolic optimization"
                    (disable-split-pc #t)]
 #:args ()
 (void)))

(define (get-syspath)
  (case (system-name)
    [("komodo") "komodo"]
    [("keystone") "keystone"]
    [("certikos") "certikos"]
    [else (error "Unknown system " (system-name))]))

(define (simulator)
  (cond
    [(use-spike) "spike"]
    [else "qemu"]))

(define make (find-executable-path "make"))
(define env (find-executable-path "env"))

(cond
  [(verify-on)
     (system* make "-s" "clean")
     (system*
       env
       (if (disable-split-pc) "DISABLE_SPLIT_PC=1" "FOO=0")
       "make"
       "-j4"
       (format "OLEVEL=~a" (optimization-level))
       "CONFIG_VERIFICATION=1"
       (format "verify-~a" (get-syspath)))
     (void)]
  [(run-on)
     (system* make "-s" "clean")
     (system*
       make
       "-j4"
       (format "OLEVEL=~a" (optimization-level))
       "CONFIG_VERIFICATION=0"
      (format "~a-~a" (simulator) (get-syspath)))
     (void)]
  [(tests-on)
     (system* make "-s" "clean")
     (system* make "-j4" "check-racket")
     (system* make "-j4" "check-riscv-tests")
     (void)]
   [(bpf-on)
     (system* make "-s" "clean")
     (system* make "-j4" "check-bpf-jit")
     (void)]
   [(tables-on)
     (system* make "-s" "clean")
     (system* "./scripts/figures.py")
     (void)]
  [else
     (error "No command")])