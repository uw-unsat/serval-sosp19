ENCMON_KERNEL_ELF        := $(O)/monitors/keystone/kernel.elf

ENCMON_KERNEL_OBJS       := $(call object,$(wildcard monitors/keystone/kernel/*.c monitors/keystone/kernel/*.S))

$(ENCMON_KERNEL_ELF): $(KERNEL_LDS) $(KERNEL_BOOT_OBJS) $(KERNEL_OBJS) $(ENCMON_KERNEL_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^
	$(Q)$(OBJDUMP) -S $@ > $(basename $@).asm
