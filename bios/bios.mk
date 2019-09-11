BIOS_LDS        := $(O)/bios/bios.lds
BIOS_OBJS       := $(call object,$(wildcard bios/*.S bios/*.c))
BIOS_BOOT_OBJS  := $(call object,$(wildcard bios/boot/*.S))
