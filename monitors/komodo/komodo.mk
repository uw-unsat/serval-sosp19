KOMONO_ELF      := $(O)/monitors/komodo.elf

KOMONO_OBJS     := $(call object,$(wildcard monitors/komodo/*.c))
KOMONO_OBJS     += $(O)/monitors/komodo/kernel.bin.o

include monitors/komodo/kernel/kernel.mk
include monitors/komodo/verif/verif.mk

$(KOMONO_ELF): $(BIOS_LDS) $(BIOS_BOOT_OBJS) $(BIOS_OBJS) $(KERNEL_OBJS) $(KOMONO_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^

qemu-komodo: $(KOMONO_ELF)
	$(QEMU) $(QEMU_OPTS) -kernel $<

spike-komodo: $(KOMONO_ELF)
	$(SPIKE) $(SPIKE_OPTS) $<

ALL             += $(KOMONO_ELF)

PHONY           += qemu-komodo spike-komodo
