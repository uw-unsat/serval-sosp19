TOYMON_KERNEL_ELF       := $(O)/monitors/toymon/kernel.elf

TOYMON_KERNEL_OBJS      := $(call object,$(wildcard monitors/toymon/kernel/*.c monitors/toymon/kernel/*.S))

$(TOYMON_KERNEL_ELF): $(KERNEL_LDS) $(KERNEL_BOOT_OBJS) $(KERNEL_OBJS) $(TOYMON_KERNEL_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^
	$(Q)$(OBJDUMP) -S $@ > $(basename $@).asm
