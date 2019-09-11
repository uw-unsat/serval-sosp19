TESTMON_TESTS   := monitors/testmon/verif/main.rkt

verify-testmon: $(TESTMON_TESTS)
	$(RACO_TEST) $^

$(TESTMON_TESTS): | \
        $(O)/monitors/testmon.asm.rkt \
        $(O)/monitors/testmon.map.rkt

PHONY           += verify-testmon

RACO_TESTS      += $(TESTMON_TESTS)
