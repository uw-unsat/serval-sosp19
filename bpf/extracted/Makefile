
DUMPS := $(wildcard *.ebpf.dump jitk/*.ebpf.dump)

all: $(patsubst %.dump,%.asm,$(DUMPS))

%.ebpf.asm: %.ebpf.bin
	../../pkg/ubpf/bin/ubpf-disassembler $^ $@

%.ebpf.bin: %.ebpf.dump
	../ebpf_dump/dump-convert.py $^ $@

.SECONDARY:

.PHONY: all
