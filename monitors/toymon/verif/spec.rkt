#lang serval/spec

(require "test.rkt")

(struct state ([x (bitvector 64)]))

(define (get-and-set st y)
  (define old-x (state-x st))
  (define new-state (struct-copy state st [x y]))
  (values new-state old-x))


(define (abs-function cpu)
  (define mr (cpu-mregions cpu))
  (define x (find-block-by-name mr 'x))
  (state (mblock-iload x null)))

(define refinement
  (forall ([s struct:state]
           [arg (bitvector 64)])
    (forall/cpu (lambda (cpu)
      (let ([pre (equal? s (abs-function cpu))])
        (let-values ([(s2 spec-result) (get-and-set s arg)]
                    [(cpu2) (cpu-ecall cpu (bv __NR_get_and_set 64) (list arg))])
          (=> pre
              (equal? (abs-function cpu2) s2))))))))

(prove refinement)