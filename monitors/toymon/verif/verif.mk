TOYMON_TESTS := \
        monitors/toymon/verif/test.rkt \

verify-toymon: $(TOYMON_TESTS)
	$(RACO_TEST) $^

verify-toymon-%: monitors/toymon/verif/%.rkt
	$(RACO_TEST) $^

$(TOYMON_TESTS): | \
        $(O)/monitors/toymon.asm.rkt \
        $(O)/monitors/toymon.map.rkt \
        $(O)/monitors/toymon.globals.rkt \
        $(O)/monitors/toymon.ll.rkt \
        $(O)/monitors/toymon/verif/asm-offsets.rkt \

$(O)/monitors/toymon.ll: $(O)/monitors/toymon/main.ll
	$(QUIET_GEN)$(LLVM_LINK) $^ | $(LLVM_OPT) -o $@~ $(LLVM_OPTFLAGS) -S
	$(Q)mv $@~ $@

PHONY           += verify-toymon
