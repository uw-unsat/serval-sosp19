#pragma once

#define COMMAND_LINE_SIZE       512

extern char boot_command_line[];

void htif_init(void);
void sifive_init(void);
void sbi_console_init(const char *color);
void time_init(void);
void uart8250_init(void);
