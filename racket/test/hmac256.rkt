#lang rosette

(require
  file/sha1
  rackunit
  rackunit/text-ui
  rosette/lib/roseunit
  (prefix-in core: serval/lib/core)
  (prefix-in llvm: serval/llvm)
  serval/lib/unittest)


(require "generated/racket/test/hmac256.ll.rkt")


(define (check-test-vector key data hex-expected)
  (define keylen (bytes-length key))
  (define datalen (bytes-length data))
  (define expected (map core:bv8 (bytes->list (hex-string->bytes hex-expected))))

  (parameterize ([llvm:current-machine (llvm:make-machine)])
    (define bkey (core:marray keylen (core:mcell 1)))
    (define input (core:marray datalen (core:mcell 1)))
    (define output (core:marray 64 (core:mcell 1)))
    ; initialize key
    (for ([i (in-range keylen)])
      (core:mblock-istore! bkey
                           (bv (bytes-ref key i) 8)
                           (list (bv i 64))))
    ; initialize input
    (for ([i (in-range datalen)])
      (core:mblock-istore! input
                           (bv (bytes-ref data i) 8)
                           (list (bv i 64))))
    (define asserted
      (with-asserts-only
        (@hmac256_hash (core:make-pointer output)
                       (core:make-pointer bkey)
                       (core:bvpointer keylen)
                       (core:make-pointer input)
                       (core:bvpointer datalen))))
    (check-equal? asserted null)
    ; extract output
    (define actual
      (for/list ([i (in-range 32)])
        (core:mblock-iload output (list (bv i 64)))))
    (check-equal? actual expected)))


(define-syntax-rule (test-vector name key data result)
  (test-case+ name (check-test-vector key data result)))

(define hmac256-tests
  (test-suite+ "Tests for HMAC-SHA-256"
    (test-vector "empty" #"" #""
     "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad")
    ; https://tools.ietf.org/html/rfc4231
    (test-vector "RFC 4231: Test Case 1"
     (make-bytes 20 #x0b) ; 20 bytes
     #"Hi There"
     "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7")
    (test-vector "RFC 4231: Test Case 2"
     #"Jefe"
     #"what do ya want for nothing?"
     "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843")
    (test-vector "RFC 4231: Test Case 3"
     (make-bytes 20 #xaa) ; 20 bytes
     (make-bytes 50 #xdd) ; 50 bytes
     "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe")
    (test-vector "RFC 4231: Test Case 4"
     (hex-string->bytes "0102030405060708090a0b0c0d0e0f10111213141516171819") ; 25 bytes
     (make-bytes 50 #xcd) ; 50 bytes
     "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b")
    ; skip Test Case 5 (truncation)
    (test-vector "RFC 4231: Test Case 6"
     (make-bytes 131 #xaa) ; 131 bytes
     #"Test Using Larger Than Block-Size Key - Hash Key First"
     "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54")
    (test-vector "RFC 4231: Test Case 7"
     (make-bytes 131 #xaa) ; 131 bytes
     #"This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm."
     "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2")
  ))

(module+ test
  (time (run-tests hmac256-tests)))
