#include <asm/csr.h>
#include <sys/types.h>

uint64_t cpu_stack[NR_CPUS][CPU_STACK_SIZE / sizeof(uint64_t)] __aligned(SZ_4K);
