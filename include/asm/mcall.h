#pragma once

#include <asm/ptrace.h>
#include <sys/types.h>

extern phys_addr_t kernel_dtb;

void mcall_init(phys_addr_t dtb);

long do_mcall(struct pt_regs *regs);

void mcall_console_putchar(uint8_t c);
noreturn void mcall_shutdown(void);
