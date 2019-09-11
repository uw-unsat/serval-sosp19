#include <asm/sbi.h>
#include <sys/console.h>
#include <sys/string.h>

static int sbi_getchar(struct console *con)
{
        return sbi_console_getchar();
}

static void sbi_putchar(struct console *con, int c)
{
        size_t i;

        if (con->color)
                for (i = 0; i < strlen(con->color); ++i)
                        sbi_console_putchar((uint8_t)con->color[i]);

        sbi_console_putchar((uint8_t)c);

        if (con->color)
                for (i = 0; i < strlen(RESET_COLOR); ++i)
                        sbi_console_putchar((uint8_t)RESET_COLOR[i]);

}

static struct console con = {
        .getchar = sbi_getchar,
        .putchar = sbi_putchar,
};

void sbi_console_init(const char *color)
{
        con.color = color;
        register_console(&con);
}
