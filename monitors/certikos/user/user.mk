ISOMON_USER_BINS        := \
        $(O)/monitors/certikos/user/idle \
        $(O)/monitors/certikos/user/alice \
        $(O)/monitors/certikos/user/bob \
        $(O)/monitors/certikos/user/hacker \

ISOMON_USER_LIBS        := \
        $(O)/monitors/certikos/user/printf.o \
        $(O)/monitors/certikos/user/string.o \
        $(O)/monitors/certikos/user/syscalls.o \

ISOMON_USER_APP_LIBS    := \
        $(O)/monitors/certikos/user/crt0.o \
        $(O)/monitors/certikos/user/lib.o \
        $(ISOMON_USER_LIBS)

$(O)/monitors/certikos/user/%: $(KERNEL_LDS) $(O)/monitors/certikos/user/%.o $(ISOMON_USER_APP_LIBS)
	$(QUIET_LD)$(LD) -o $@ $(LDFLAGS) -T $^

$(O)/monitors/certikos/user/%.o: CFLAGS += -I $(O)/monitors/certikos/user

# we use medany; the link address should be within 2G of pc
# CONFIG_DRAM_START should be good enough since we are lazy
$(O)/monitors/certikos/initrd.elf: $(O)/monitors/certikos/user/init.o $(O)/monitors/certikos/user/loader.o $(ISOMON_USER_LIBS)
	$(QUIET_LD)$(LD) -o $@ -static -Ttext $(CONFIG_DRAM_START) $(LDFLAGS) $^

$(O)/monitors/certikos/user/init.o: $(ISOMON_USER_BINS)
