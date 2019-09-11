KOMONO_KERNEL_ELF       := $(O)/monitors/komodo/kernel.elf

KOMONO_KERNEL_OBJS      := $(call object,$(wildcard monitors/komodo/kernel/*.c monitors/komodo/kernel/*.S))

$(KOMONO_KERNEL_ELF): $(KERNEL_LDS) $(KERNEL_BOOT_OBJS) $(KERNEL_OBJS) $(KOMONO_KERNEL_OBJS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^
	$(Q)$(OBJDUMP) -S $@ > $(basename $@).asm
