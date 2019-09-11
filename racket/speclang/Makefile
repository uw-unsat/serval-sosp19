
VS     := $(wildcard *.v)

V               = @
Q               = $(V:1=)
QUIET_GEN       = $(Q:@=@echo    '     GEN        '$@;)
QUIET_COQC      = $(Q:@=@echo    '     COQC       '$@;)
QUIET_RACKET    = $(Q:@=@echo    '     RACKET     '$@;)


check: test.rkt speclang.rkt extracted.rkt
	$(QUIET_RACKET)racket test.rkt

%.vo: %.v
	$(QUIET_COQC)coqc $*.v

extracted.rkt.scm: test.vo

define gen-rkt
	(echo "#lang rosette/safe"; \
	 echo '(require "speclang.rkt")'; \
	 echo '(require "macros_extr.rkt")'; \
	 tail +4 "$^"; \
	 echo '(provide (all-defined-out))';) > "$@"
endef

extracted.rkt: extracted.rkt.scm
	$(QUIET_GEN)$(gen-rkt)

.PHONY: check
.SECONDARY: .depend

.depend: $(VS)
	@coqdep $^ > $@

include .depend
