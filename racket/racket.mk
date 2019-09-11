LLVM_ROSETTE            := $(O)/racket/llvm-rosette/llvm-rosette
SERVAL_LLVM             := racket serval/serval/bin/serval-llvm.rkt
PYTHON_ROSETTE          := racket/python-rosette/python-rosette.py
EBPF_ROSETTE            := racket/ebpf-rosette/ebpf-rosette.py

LLVM_ROSETTE_OBJS       := $(call object,$(wildcard racket/llvm-rosette/*.cc))
RACKET_TEST_C_SRCS      := $(wildcard racket/test/*.c)
RACKET_TEST_S_SRCS      := $(wildcard racket/test/*.S)
RACKET_TEST_PY_SRCS     := $(wildcard racket/test/*.py)

$(O)/racket/%.o: racket/%.cc
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_CXX)$(HOST_CXX) -o $@ -c -Wno-unknown-warning-option $(LLVM_CXXFLAGS) $<

$(LLVM_ROSETTE): $(LLVM_ROSETTE_OBJS)
	$(QUIET_LD)$(HOST_CXX) -o $@ $^ $(LLVM_LDFLAGS) $(LLVM_LIBS)

# keep LLVM_ROSETTE around for now
%.ll.rkt: %.ll $(LLVM_ROSETTE)
#	$(QUIET_GEN)$(LLVM_ROSETTE) $< > $@~
	$(QUIET_GEN)$(SERVAL_LLVM) < $< > $@~
	$(Q)mv $@~ $@

%.globals.rkt: %.elf
	$(Q)echo "#lang reader serval/lang/dwarf" > $@~
	$(QUIET_GEN)$(OBJDUMP) --dwarf=info $< >> $@~
	$(Q)mv $@~ $@

%.asm.rkt: %.asm
	$(QUIET_GEN)echo "#lang reader serval/riscv/objdump" > $@~ && \
		cat $< >> $@~
	$(Q)mv $@~ $@

%.map.rkt: %.map
	$(QUIET_GEN)echo "#lang reader serval/lang/nm" > $@~ && \
		cat $< >> $@~
	$(Q)mv "$@~" "$@"

$(O)/%.py.rkt: %.py $(PYTHON_ROSETTE)
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_GEN)$(PYTHON_ROSETTE) $< > $@~
	$(Q)mv $@~ $@

%/asm-offsets.rkt: %/asm-offsets.S
	$(QUIET_GEN)$(call gen-offsets-rkt) < $< > $@~
	$(Q)mv $@~ $@

$(O)/%.ebpf.bin: %.ebpf
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_GEN)$(UBPF_ASSEMBLER) $^ $@

$(O)/%.ebpf.rkt: $(O)/%.ebpf.bin $(EBPF_ROSETTE)
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_GEN)$(UBPF_DISASSEMBLER) $< - | $(EBPF_ROSETTE) - > $@

$(O)/%.ll: %.c
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_CC)$(LLVM_CC) -o $@ -mno-sse -S -emit-llvm -fno-discard-value-names $(UBSAN_CFLAGS) -Wno-unused-command-line-argument -I include $(filter-out -g,$(BASE_CFLAGS)) $(CONFIG_CFLAGS) -DCONFIG_VERIFICATION_LLVM -c $<

$(O)/racket/test/%.elf: $(O)/racket/test/%.o
	$(QUIET_LD)$(LD) -o $@ -e $(CONFIG_DRAM_START) -Ttext $(CONFIG_DRAM_START) $(filter-out --gc-sections,$(LDFLAGS)) $<

$(patsubst %.c,%.rkt,$(RACKET_TEST_C_SRCS)): | $(addprefix $(O)/,\
        $(patsubst %.c,%.ll.rkt,$(RACKET_TEST_C_SRCS)) \
        $(patsubst %.c,%.asm.rkt,$(RACKET_TEST_C_SRCS)) \
        $(patsubst %.c,%.map.rkt,$(RACKET_TEST_C_SRCS)) \
        $(patsubst %.c,%.globals.rkt,$(RACKET_TEST_C_SRCS)))

$(patsubst %.S,%.rkt,$(RACKET_TEST_S_SRCS)): | $(addprefix $(O)/,\
        $(patsubst %.S,%.asm.rkt,$(RACKET_TEST_S_SRCS)))

$(patsubst %.py,%.rkt,$(RACKET_TEST_PY_SRCS)): | $(addprefix $(O)/,\
        $(patsubst %.py,%.py.rkt,$(RACKET_TEST_PY_SRCS)))

racket/test/sha256.rkt: | $(O)/racket/test/sha256.ll.rkt

$(O)/racket/test/sha256.ll: $(O)/kernel/sha256.ll $(O)/kernel/hacl/Hacl_SHA2_256.ll
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_GEN)$(LLVM_LINK) $^ | $(LLVM_OPT) -o $@~ $(LLVM_OPTFLAGS) -S
	$(Q)mv $@~ $@

racket/test/hmac256.rkt: | $(O)/racket/test/hmac256.ll.rkt

$(O)/racket/test/hmac256.ll: $(O)/kernel/hmac256.ll $(O)/kernel/hacl/Hacl_HMAC_SHA2_256.ll
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_GEN)$(LLVM_LINK) $^ | $(LLVM_OPT) -o $@~ $(LLVM_OPTFLAGS) -S
	$(Q)mv $@~ $@

check-racket: $(wildcard racket/test/*.rkt)
	$(RACO_TEST) $^

check-racket-%: racket/test/%.rkt
	$(RACO_TEST) $^

include racket/test/riscv-tests/riscv-tests.mk

PHONY           += check-racket

PRECIOUS        += %.ll.rkt %.S.rkt $(O)/%.ll $(O)/%.S $(O)/racket/test/%.elf

RACO_TESTS      += $(wildcard racket/test/*.rkt)
