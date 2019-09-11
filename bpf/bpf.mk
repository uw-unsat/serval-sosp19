bpf/kbpf.rkt |: $(O)/bpf/kbpf.ll.rkt

check-bpf: check-bpf-poc check-bpf-jit

check-bpf-poc: $(wildcard bpf/poc/*.rkt)
	$(RACO_TEST) $^

check-bpf-jit: $(wildcard bpf/jit/test/*.rkt)
	$(RACO_TEST) $^

check-bpf-poc-%: bpf/poc/%.rkt
	$(RACO_TEST) $^

PHONY           += check-bpf check-bpf-poc check-bpf-jit
