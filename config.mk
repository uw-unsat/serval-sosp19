# CPU architecture
ARCH                    = riscv64

# output directory
O                       = o.$(ARCH)

# Number of host processors
NPROC                   = $(shell nproc 2> /dev/null)
ifeq ($(NPROC),)
NPROC                   = 4
endif

# optimization level
OLEVEL                  = 2

# number of CPUs used in simulation
CONFIG_NR_CPUS          = 5

# CPU to boot up initially
CONFIG_BOOT_CPU         = 1

# DRAM start address
CONFIG_DRAM_START       = 0x80000000

# verification build (0 - off; 1 - on)
CONFIG_VERIFICATION     = 1

# configuration used by QEMU for simulation
QEMU                    = qemu-system-$(ARCH)
QEMU_MACHINE            = virt
QEMU_OPTS               = -smp cpus=$(CONFIG_NR_CPUS) -nographic -machine $(QEMU_MACHINE)
QEMU_USER               = qemu-$(ARCH)
QEMU_DEBUG              = -S -s

# GDB configuration
GDB_OPTS                = -ex 'target remote :1234'

# configuration used by Spike for simulation
SPIKE                   = spike
SPIKE_OPTS              = -p$(CONFIG_NR_CPUS)

# Racket configuration
RACO_JOBS               = $(NPROC)
RACO_TIMEOUT            = 1200
RACO_TEST               = raco test --check-stderr --table --timeout $(RACO_TIMEOUT) --jobs $(RACO_JOBS)

DOCKER_IMAGE            = lukenels/sequoia-tools:latest

# overwrite using local settings
-include                local.mk
