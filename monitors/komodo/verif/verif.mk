KOMONO_TESTS := \
        monitors/komodo/verif/llvm.rkt \
        monitors/komodo/verif/riscv.rkt \
        monitors/komodo/verif/nickel-ni.rkt \
        monitors/komodo/verif/invariants.rkt \
        monitors/komodo/verif/basic.rkt \

verify-komodo: $(KOMONO_TESTS)
	$(RACO_TEST) $^

verify-komodo-%: monitors/komodo/verif/%.rkt
	$(RACO_TEST) $^

$(KOMONO_TESTS): | \
        $(O)/monitors/komodo.asm.rkt \
        $(O)/monitors/komodo.map.rkt \
        $(O)/monitors/komodo.globals.rkt \
        $(O)/monitors/komodo.ll.rkt \
        $(O)/monitors/komodo/verif/asm-offsets.rkt

$(O)/monitors/komodo.ll: $(O)/monitors/komodo/monitor.ll \
                         $(O)/monitors/komodo/traps.ll \
                         $(O)/kernel/smp.ll \
                         $(O)/kernel/ptrace.ll \
                         $(O)/bios/mcall.ll
	$(QUIET_GEN)$(LLVM_LINK) $^ | $(LLVM_OPT) -o $@~ $(LLVM_OPTFLAGS) -S
	$(Q)mv $@~ $@

PHONY           += verify-komodo
