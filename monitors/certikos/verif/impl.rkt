#lang rosette/safe

(require
  "state.rkt"
  serval/lib/core
  (prefix-in riscv: serval/riscv/objdump)
  (prefix-in certikos: "generated/monitors/certikos/verif/asm-offsets.rkt"))

(provide (all-defined-out))


(define (mregions-abstract mregions)

  (define block-current-pid (find-block-by-name mregions 'current_pid))
  (define block-pages (find-block-by-name mregions 'pages))
  (define block-procs (find-block-by-name mregions 'procs))

  (define-symbolic* page.owner (~> (bitvector 64) (bitvector 64)))

  (state (mblock-iload block-current-pid null)
         (lambda (pindex poffset)
           (mblock-iload block-pages (list pindex poffset)))
         (lambda (pid)
           (mblock-iload block-procs (list pid 'state)))
         (lambda (pid)
           (mblock-iload block-procs (list pid 'next)))
         (lambda (pid)
           (mblock-iload block-procs (list pid 'owner)))
         (lambda (pid)
           (mblock-iload block-procs (list pid 'lower)))
         (lambda (pid)
           (mblock-iload block-procs (list pid 'upper)))
         page.owner
         (lambda (pid)
           (regs
             (mblock-iload block-procs (list pid 'cpu 'ra))
             (mblock-iload block-procs (list pid 'cpu 'sp))
             (mblock-iload block-procs (list pid 'cpu 'gp))
             (mblock-iload block-procs (list pid 'cpu 'tp))
             (mblock-iload block-procs (list pid 'cpu 't0))
             (mblock-iload block-procs (list pid 'cpu 't1))
             (mblock-iload block-procs (list pid 'cpu 't2))
             (mblock-iload block-procs (list pid 'cpu 's0))
             (mblock-iload block-procs (list pid 'cpu 's1))
             (mblock-iload block-procs (list pid 'cpu 'a0))
             (mblock-iload block-procs (list pid 'cpu 'a1))
             (mblock-iload block-procs (list pid 'cpu 'a2))
             (mblock-iload block-procs (list pid 'cpu 'a3))
             (mblock-iload block-procs (list pid 'cpu 'a4))
             (mblock-iload block-procs (list pid 'cpu 'a5))
             (mblock-iload block-procs (list pid 'cpu 'a6))
             (mblock-iload block-procs (list pid 'cpu 'a7))
             (mblock-iload block-procs (list pid 'cpu 's2))
             (mblock-iload block-procs (list pid 'cpu 's3))
             (mblock-iload block-procs (list pid 'cpu 's4))
             (mblock-iload block-procs (list pid 'cpu 's5))
             (mblock-iload block-procs (list pid 'cpu 's6))
             (mblock-iload block-procs (list pid 'cpu 's7))
             (mblock-iload block-procs (list pid 'cpu 's8))
             (mblock-iload block-procs (list pid 'cpu 's9))
             (mblock-iload block-procs (list pid 'cpu 's10))
             (mblock-iload block-procs (list pid 'cpu 's11))
             (mblock-iload block-procs (list pid 'cpu 't3))
             (mblock-iload block-procs (list pid 'cpu 't4))
             (mblock-iload block-procs (list pid 'cpu 't5))
             (mblock-iload block-procs (list pid 'cpu 't6))

             (mblock-iload block-procs (list pid 'satp))
             (mblock-iload block-procs (list pid 'scause))
             (mblock-iload block-procs (list pid 'scounteren))
             (mblock-iload block-procs (list pid 'sepc))
             (mblock-iload block-procs (list pid 'sscratch))
             (mblock-iload block-procs (list pid 'sstatus))
             (mblock-iload block-procs (list pid 'stvec))
             (mblock-iload block-procs (list pid 'stval))
             (mblock-iload block-procs (list pid 'mepc))
             (mblock-iload block-procs (list pid 'sip))
             (mblock-iload block-procs (list pid 'sie))))

           ; Current regs
           (zero-regs)))



(define (mregions-invariants mregions)

  (define block-procs (find-block-by-name mregions 'procs))
  (define block-current-pid (find-block-by-name mregions 'current_pid))
  (define current-pid (mblock-iload block-current-pid null))

  (define-symbolic pid q (bitvector 64))
  (define (pid->lower pid)
    (mblock-iload block-procs (list pid 'lower)))
  (define (pid->upper pid)
    (mblock-iload block-procs (list pid 'upper)))
  (define (pid->owner pid)
    (mblock-iload block-procs (list pid 'owner)))
  (define (pid->next pid)
    (mblock-iload block-procs (list pid 'next)))
  (define (pid->csr pid csr)
    (mblock-iload block-procs (list pid csr)))
  (define (pid-run? pid)
    (proc.state-run? (mblock-iload block-procs (list pid 'state))))
  (&& ; current pid is valid
      (pid-valid? current-pid)
      ; current pid is runnable
      (pid-run? current-pid)
      ; every valid pid's owner is valid
      (forall (var pid) (=> (pid-valid? pid)
                            (pid-valid? (pid->owner pid))))
      ; for each process: quota <= top <= NR_PAGES
      (forall (var pid) (=> (pid-valid? pid)
                             (&& (bvule (pid->upper pid) (bv certikos:NR_PAGES 64))
                                 (bvule (pid->lower pid) (pid->upper pid)))))
      (forall (var pid)
        (=> (&& (pid-valid? pid) (pid-run? pid))
          (&& (pid-valid? (pid->next pid))
              (pid-run? (pid->next pid)))))

      ; Non-running processes have zeroed CSRs
      (forall (var pid) (=> (&& (pid-valid? pid) (! (pid-run? pid)))
                          (&& (bveq (pid->csr pid 'satp) (bv 0 64))
                              (bveq (pid->csr pid 'scause) (bv 0 64))
                              (bveq (pid->csr pid 'scounteren) (bv 0 64))
                              (bveq (pid->csr pid 'sepc) (bv 0 64))
                              (bveq (pid->csr pid 'sscratch) (bv 0 64))
                              (bveq (pid->csr pid 'sstatus) (bv 0 64))
                              (bveq (pid->csr pid 'stvec) (bv 0 64))
                              (bveq (pid->csr pid 'stval) (bv 0 64))
                              (bveq (pid->csr pid 'sip) (bv 0 64))
                              (bveq (pid->csr pid 'sie) (bv 0 64)))))
      ; Saved CSRs are only ever the masked versions
      (forall (var pid) (=> (pid-valid? pid)
                              (&& (bveq (bvand (bvnot riscv:sstatus-mask) (pid->csr pid 'sstatus)) (bv 0 64))
                                  (bveq (bvand (bvnot riscv:sie-mask) (pid->csr pid 'sie)) (bv 0 64))
                                  (bveq (bvand (bvnot riscv:sip-mask) (pid->csr pid 'sip)) (bv 0 64)))))))
