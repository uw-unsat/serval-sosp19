#include <sys/console.h>
#include <sys/of.h>

#define HTIF_DEV_SYSCALL        0
#define HTIF_DEV_CONSOLE        1

#define HTIF_CMD_WRITE          1

volatile uint64_t tohost __section(.htif);
volatile uint64_t fromhost __section(.htif);

static bool has_htif;

static void wait(void)
{
        while (tohost) {
                uint64_t val = fromhost;

                if (!val)
                        continue;
                fromhost = 0;
        }
}

static void write_tohost(uint64_t dev, uint64_t cmd, uint64_t data)
{
        wait();
        tohost = (dev << 56) | (cmd << 48) | data;
}

static void htif_putchar(struct console *con, int c)
{
        write_tohost(HTIF_DEV_CONSOLE, HTIF_CMD_WRITE, (uint8_t)c);
}

static struct console con = {
        .putchar = htif_putchar,
};

void htif_init(void)
{
        has_htif = !!of_find_node_by_path("/htif");
        if (!has_htif)
                return;
        register_console(&con);
}

void htif_shutdown(void)
{
        if (!has_htif)
                return;

        /* (payload & 1) means exit, with value (payload >> 1) */
        while (1)
                write_tohost(HTIF_DEV_SYSCALL, 0, 1);
}
