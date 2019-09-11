#lang rosette

(require rosette/lib/roseunit)

(require "extracted.rkt")
(require "speclang.rkt")

(for [(thm (decode-list r_theorems))]
  (check-theorem thm))
