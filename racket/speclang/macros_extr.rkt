#lang racket

(require (rename-in racket (match racket-match)))

(define-syntax (@ stx)
  (syntax-case stx ()
    [(_ f x) #'(f x)]
    [(_ f x r ...) #'(@ (f x) r ...)]))

(define-syntax (lambdas stx)
  (syntax-case stx ()
    [(_ (n) body) #'(lambda (n) body)]
    [(_ (n r ...) body) #'(lambda (n) (lambdas (r ...) body))]))

(define-match-expander scheme-fix
  (lambda (stx)
    (syntax-case stx ()
      [(_ A c ...) #'(quasiquote (A (unquote c) ...))])))

(define-syntax (match stx)
  (syntax-case stx ()
   [(_ term [(c ...) b] ...) (syntax (racket-match term [(scheme-fix c ...) b] ...))]))

(provide (all-defined-out))
