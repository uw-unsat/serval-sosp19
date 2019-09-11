#lang rosette

(require rosette/lib/roseunit)

(define-syntax (lambdas stx)
  (syntax-case stx ()
    [(_ (n) body) #'(lambda (n) body)]
    [(_ (n r ...) body) #'(lambda (n) (lambdas (r ...) body))]))

(define (decode-boolean x)
  (match x
    ['(True) #t]
    ['(False) #f]))

(define (decode-nat n)
  (match n
    [`(O) 0]
    [`(S ,x) (+ 1 (decode-nat x))]
    [n n]))

(define (decode-integer z)
  (match z
    (`(Z0) 0)
    (`(Zneg ,r) (- (decode-integer r)))
    (`(Zpos ,r) (decode-integer r))
    (`(XI ,r) (+ 1 (* 2 (decode-integer r))))
    (`(XO ,r) (* 2 (decode-integer r)))
    (`(XH) 1)))

(define (decode-ascii ascii)
  (match ascii
    [(cons '(True) rest) (+ 1 (* 2 (decode-ascii rest)))]
    [(cons '(False) rest) (* 2 (decode-ascii rest))]
    [null 0]))

(define (decode-string str)
  (match str
    [`(EmptyString) ""]
    [`(String (Ascii ,r ...) ,str2)
        (string-append (string (integer->char (decode-ascii r)))
                       (decode-string str2))]))

(define (decode-list thms)
  (match thms
    [`(Nil) null]
    [`(Cons ,x ,xs) (cons x (decode-list xs))]))

(define decode-bv (lambdas (w v)
  (bv (decode-integer v) (decode-nat w))))

(define (decode-proxy prox)
  (match prox
    [`(Proxy_Integer) integer?]
    [`(Proxy_Boolean) boolean?]))

(define integer-add (lambdas (x y)
  (+ x y)))

(define integer-sub (lambdas (x y)
  (- x y)))

(define integer-gt (lambdas (x y)
  (> x y)))

(define integer-equal (lambdas (x y)
  (equal? x y)))

(define integer-forall (lambda (f)
  (begin
    (define-symbolic* i integer?)
    (forall (list i) (f i)))))

(define integer-ite (lambdas (b x y)
  (if b x y)))

(define boolean-or (lambdas (x y)
  (|| x y)))

(define boolean-and (lambdas (x y)
  (&& x y)))

(define boolean-ite (lambdas (b x y)
  (if b x y)))

(define boolean-implies (lambdas (x y)
  (implies x y)))

(define boolean-equal (lambdas (x y)
  (equal? x y)))

(define boolean-forall (lambda (f)
  (begin
    (define-symbolic* b boolean?)
    (forall (list b) (f b)))))


(define (check-theorem thm)
  (match thm
    [`(Proposition ,p) (check-unsat (verify (assert p)))]
    [`(With_var ,t1 ,f)
        (begin
          (define-symbolic* x (decode-proxy t1))
          (check-theorem (f x)))]
    [`(With_uf ,t1 ,t2 ,f)
        (begin
          (define-symbolic* g (~> (decode-proxy t1) (decode-proxy t2)))
          (check-theorem (f g)))]))

; Coq will call bitvector functions with an extra width
; parameter so here we drop all of them

(define bveq-w (lambdas (w x y) (bveq x y)))

(define bvadd-w (lambdas (w x y) (bvadd x y)))
(define bvsub-w (lambdas (w x y) (bvsub x y)))
(define bvmul-w (lambdas (w x y) (bvmul x y)))
(define bvsdiv-w (lambdas (w x y) (bvsdiv x y)))
(define bvudiv-w (lambdas (w x y) (bvudiv x y)))
(define bvsrem-w (lambdas (w x y) (bvsrem x y)))
(define bvurem-w (lambdas (w x y) (bvurem x y)))
(define bvsmod-w (lambdas (w x y) (bvsmod x y)))
(define bvand-w (lambdas (w x y) (bvand x y)))
(define bvor-w (lambdas (w x y) (bvor x y)))
(define bvxor-w (lambdas (w x y) (bvxor x y)))
(define bvshl-w (lambdas (w x y) (bvshl x y)))
(define bvlshr-w (lambdas (w x y) (bvlshr x y)))
(define bvashr-w (lambdas (w x y) (bvashr x y)))
(define bvnot-w (lambdas (w x) (bvnot x)))
(define bvneg-w (lambdas (w x) (bvneg x)))

(provide (except-out (all-defined-out) lambdas))