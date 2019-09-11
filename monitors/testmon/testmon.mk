TESTMON_ELF     := $(O)/monitors/testmon.elf
TESTMON_BIN     := $(basename $(TESTMON_ELF)).bin

TESTMON_OBJS    := $(call object,$(wildcard monitors/testmon/*.c monitors/testmon/*.S))

$(TESTMON_ELF): $(BIOS_LDS) $(BIOS_BOOT_OBJS) $(BIOS_OBJS) $(KERNEL_OBJS) $(TESTMON_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^

qemu-testmon: $(TESTMON_ELF)
	$(QEMU) $(QEMU_OPTS) -kernel $<

qemu-gdb-testmon: QEMU_OPTS += $(QEMU_DEBUG)
qemu-gdb-testmon: qemu-testmon

gdb-testmon: $(TESTMON_ELF)
	$(GDB) $< $(GDB_OPTS)

spike-testmon: $(TESTMON_ELF)
	$(SPIKE) $(SPIKE_OPTS) $<

$(TESTMON_OBJS): CFLAGS += -I monitors/testmon/filters

include monitors/testmon/verif/verif.mk

PHONY           += qemu-testmon qemu-gdb-testmon gdb-testmon spike-testmon
