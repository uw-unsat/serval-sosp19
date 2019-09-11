
ENCMON_TESTS    := \
        monitors/keystone/verif/ni.rkt \

verify-keystone: $(ENCMON_TESTS)
	$(RACO_TEST) $^

verify-keystone-%: monitors/keystone/verif/%.rkt
	$(RACO_TEST) $^

$(ENCMON_TESTS): | \
        $(O)/monitors/keystone/verif/asm-offsets.rkt

ENCMON_LLS      := \
        $(O)/monitors/keystone/pmp.ll \
        $(O)/monitors/keystone/enclave.ll \
        $(O)/monitors/keystone/main.ll \
        $(O)/monitors/keystone/traps.ll \
        $(O)/kernel/ptrace.ll \
        $(O)/kernel/smp.ll \

$(O)/monitors/keystone.ll: $(ENCMON_LLS)
	$(QUIET_GEN)$(LLVM_LINK) $^ | $(LLVM_OPT) -o $@~ $(LLVM_OPTFLAGS) -S
	$(Q)mv $@~ $@

monitors/keystone/verif/keystone.rkt: | \
        $(O)/monitors/keystone.ll.rkt \
        $(O)/monitors/keystone.globals.rkt \
        $(O)/monitors/keystone.map.rkt \

$(O)/monitors/keystone.map: $(O)/monitors/keystone.ll
	$(QUIET_GEN)$(LLVM_ROSETTE) --symbols $< > $@~
	$(Q)mv $@~ $@

# check-keystone: monitors/keystone/verif/keystone.rkt
# $(RACO_TEST) $^

PHONY           += verify-keystone

RACO_TESTS      += $(ENCMON_TESTS)
