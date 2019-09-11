TOYMON_ELF      := $(O)/monitors/toymon.elf

TOYMON_OBJS     := $(call object,$(wildcard monitors/toymon/*.c monitors/toymon/*.S))
TOYMON_OBJS     += $(O)/monitors/toymon/kernel.bin.o

include monitors/toymon/kernel/kernel.mk
include monitors/toymon/verif/verif.mk

$(TOYMON_ELF): $(BIOS_LDS) $(BIOS_BOOT_OBJS) $(BIOS_OBJS) $(KERNEL_OBJS) $(TOYMON_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^

qemu-toymon: $(TOYMON_ELF)
	$(QEMU) $(QEMU_OPTS) -kernel $<

spike-toymon: $(TOYMON_ELF)
	$(SPIKE) $(SPIKE_OPTS) $<

ALL             += $(TOYMON_ELF)

PHONY           += qemu-toymon spike-toymon
