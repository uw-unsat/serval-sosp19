#pragma once

#include <asm/setup.h>
#include <sys/types.h>

/* Colors */
#define BRIGHT_RED      "\x1b[31;1m"
#define BRIGHT_GREEN    "\x1b[32;1m"
#define BRIGHT_YELLOW   "\x1b[33;1m"
#define BRIGHT_BLUE     "\x1b[34;1m"
#define BRIGHT_MAGENTA  "\x1b[35;1m"
#define BRIGHT_CYAN     "\x1b[36;1m"
#define BRIGHT_WHITE    "\x1b[37;1m"
#define RESET_COLOR     "\x1b[0m"

struct console {
        int (*getchar)(struct console *);
        void (*putchar)(struct console *, int c);
        const char *color;
        struct list_head list;
};

void register_console(struct console *);

int console_getchar(void);
void console_putchar(char c);
void console_write(const char *s, size_t n);
