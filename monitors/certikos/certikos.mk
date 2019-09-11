ISOMON_ELF      := $(O)/monitors/certikos.elf

ISOMON_OBJS     := $(call object,$(wildcard monitors/certikos/*.c monitors/certikos/*.S))
ISOMON_OBJS     += $(O)/monitors/certikos/initrd.bin.o

include monitors/certikos/user/user.mk
include monitors/certikos/verif/verif.mk

$(ISOMON_ELF): $(BIOS_LDS) $(BIOS_BOOT_OBJS) $(BIOS_OBJS) $(KERNEL_OBJS) $(ISOMON_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^

qemu-certikos: $(ISOMON_ELF)
	$(QEMU) $(QEMU_OPTS) -kernel $<

spike-certikos: $(ISOMON_ELF)
	$(SPIKE) $(SPIKE_OPTS) $<

ALL             += $(ISOMON_ELF)

PHONY           += qemu-certikos spike-certikos certikos-gcc-asm
