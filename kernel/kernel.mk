KERNEL_LDS              := $(O)/kernel/kernel.lds
KERNEL_OBJS             := $(call object,$(wildcard kernel/*.S kernel/*.c kernel/libfdt/*.c kernel/hacl/*.c))
KERNEL_BOOT_OBJS        := $(call object,$(wildcard kernel/boot/*.S))

include/asm/asm-offsets.h: $(O)/kernel/asm-offsets.S
	$(QUIET_GEN)$(call gen-offsets) < $< > $@~
	$(Q)mv $@~ $@

$(O)/kernel/libfdt/%.o: CFLAGS += -I kernel/libfdt
