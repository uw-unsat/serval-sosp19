#lang rosette/safe

(require rosette/lib/roseunit)

(define uid_t (bitvector 32)) ; user id
(define ino_t (bitvector 64)) ; file id
(define val_t (bitvector 64)) ; file content (dummy)

(struct state (perm data) #:transparent)

(define (make-state)
  (define-symbolic* newperm (~> ino_t uid_t))
  (define-symbolic* newdata (~> ino_t val_t))
  (state newperm newdata))

(define (make-uid)
  (define-symbolic* newuid uid_t)
  newuid)

(define (make-ino)
  (define-symbolic* newino ino_t)
  newino)

(define (vieweqv u s t)
  (define-symbolic ino ino_t)
  (&& (forall (list ino) (equal? ((state-perm s) ino) ((state-perm t) ino))) ; permission is public
      (forall (list ino) (=> (equal? u ((state-perm s) ino))                 ; file data owned by u
                             (equal? ((state-data s) ino) ((state-data t) ino))))))

(define (perm? s u ino)
  (equal? u ((state-perm s) ino)))

; return the content of ino (or 0 if not permitted)
(define (read s u ino)
  (cons s (if (perm? s u ino)
              ((state-data s) ino)
              (integer->bitvector 0 val_t))))

; change the ownership of ino
(define (chown s u ino to)
  (define perm (state-perm s))
  (define data (state-data s))
  (define ns (state (lambda (x) (if (equal? x ino) to (perm x))) data))
  (cons (if (perm? s u ino) ns s) (bv 0 32)))

; output consistency: s ~dom(a) t => output(s, a) = output(t, a)
(define (OC u s t f)
  (=> (vieweqv u s t) (equal? (cdr (f s)) (cdr (f t)))))

; step consistency: s ~u t => step(s, a) ~u step(t, a)
(define (SC u s t f)
  (=> (vieweqv u s t) (vieweqv u (car (f s)) (car (f t)))))

(define (SC-relaxed pre u s t f)
  (=> (&& pre (vieweqv u s t)) (vieweqv u (car (f s)) (car (f t)))))

(define (WSC au u s t f)
  (=> (&& (vieweqv au s t) (vieweqv u s t)) (vieweqv u (car (f s)) (car (f t)))))

(define (flowsto? x0 x1 y0 y1)
  (|| (equal? x0 y0) (equal? x1 y0)))

(define (SR au0 au1 u0 u1 s t f)
  (=> (&& (! (flowsto? au0 au1 u0 u1)) (vieweqv u0 s t)) (vieweqv u0 (car (f s)) (car (f t)))))

(define (WSC+SR au0 au1 u0 u1 s t f)
  (=> (&& (=> (flowsto? au0 au1 u0 u1) (vieweqv au0 s t)) (vieweqv u0 s t)) (vieweqv u0 (car (f s)) (car (f t)))))

(define (test)
  (define u (make-uid))
  (define s (make-state))
  (define t (make-state))
  (define to (make-uid))
  (define ino (make-ino))
  ; actions
  (define au (make-uid))
  (define aread (lambda (x) (read x au ino)))
  (define achown (lambda (x) (chown x au ino to)))

  ; OC
  (check-unsat (verify (assert (OC au s t aread))))
  (check-unsat (verify (assert (OC au s t achown))))

  ; SC
  (check-unsat (verify (assert (SC u s t aread))))
  (check-sat (verify (assert (SC u s t achown)))) ; chown violates SC

  ; SC (relaxed)
  ; Figure 12 of the SFSCQ paper: file_data st0 f = file_data st1 f \/ viewer <> new_owner
  (define chown-pre (|| (equal? ((state-data s) ino) ((state-data t) ino))
                        (! (equal? u to))))
  (check-unsat (verify (assert (SC-relaxed chown-pre u s t achown))))

  ; intransitive policy: a domain is a pair of UIDs (u, v)
  ; one may consider this as RW for u and W for v
  ; for regular operations, dom(a) is simply (u, u)
  ; for chown from u to v, dom(a) is (u, v)
  ; equivalence ~(u, v) is simply ~u

  ; WSC
  (check-unsat (verify (assert (WSC au u s t aread))))
  (check-unsat (verify (assert (WSC au u s t achown))))

  ; SR
  (define v (make-uid))
  (check-unsat (verify (assert (SR au au u v s t aread))))
  (check-unsat (verify (assert (SR au to u v s t achown))))

  ; WSC /\ SR
  (check-unsat (verify (assert (WSC+SR au au u v s t aread))))
  (check-unsat (verify (assert (WSC+SR au to u v s t achown))))

  ; compare
  (define cond0 (SC-relaxed chown-pre u s t achown))
  (define cond1 (WSC+SR au to u v s t achown))
  (verify (assert (<=> cond0 cond1))))

(test)
