ENCMON_ELF      := $(O)/monitors/keystone.elf

ENCMON_OBJS     := $(call object,$(wildcard monitors/keystone/*.c) $(wildcard monitors/keystone/*.S))
ENCMON_GCC_ASM  := $(O)/monitors/keystone/enclave.S
ENCMON_OBJS     += $(O)/monitors/keystone/kernel.bin.o

$(ENCMON_ELF): $(BIOS_LDS) $(BIOS_BOOT_OBJS) $(BIOS_OBJS) $(KERNEL_OBJS) $(ENCMON_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^

keystone-gcc-asm: $(ENCMON_GCC_ASM)

qemu-keystone: $(ENCMON_ELF)
	$(QEMU) $(QEMU_OPTS) -kernel $<

spike-keystone: $(ENCMON_ELF)
	$(SPIKE) $(SPIKE_OPTS) $<

include monitors/keystone/kernel/kernel.mk
include monitors/keystone/verif/verif.mk

ALL             += $(ENCMON_ELF)

PHONY           += qemu-keystone spike-keystone keystone-gcc-asm
