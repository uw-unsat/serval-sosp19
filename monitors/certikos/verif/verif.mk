ISOMON_TESTS := \
        monitors/certikos/verif/llvm.rkt \
        monitors/certikos/verif/riscv.rkt \
        monitors/certikos/verif/basic.rkt \
        monitors/certikos/verif/ni.rkt \
        monitors/certikos/verif/nickel-ni.rkt \
        monitors/certikos/verif/invariants.rkt \

verify-certikos: $(ISOMON_TESTS)
	$(RACO_TEST) $^

verify-certikos-%: monitors/certikos/verif/%.rkt
	$(RACO_TEST) $^

$(ISOMON_TESTS): | \
        $(O)/monitors/certikos.asm.rkt \
        $(O)/monitors/certikos.map.rkt \
        $(O)/monitors/certikos.globals.rkt \
        $(O)/monitors/certikos.ll.rkt \
        $(O)/monitors/certikos/verif/asm-offsets.rkt

$(O)/monitors/certikos.ll: $(O)/monitors/certikos/proc.ll \
                         $(O)/monitors/certikos/traps.ll \
                         $(O)/monitors/certikos/main.ll \
                         $(O)/kernel/smp.ll
	$(QUIET_GEN)$(LLVM_LINK) $^ | $(LLVM_OPT) -o $@~ $(LLVM_OPTFLAGS) -S
	$(Q)mv $@~ $@

PHONY           += verify-certikos

RACO_TESTS      += $(ISOMON_TE2STS)
