#include <asm/io.h>
#include <asm/processor.h>
#include <sys/console.h>
#include <sys/errno.h>
#include <sys/of.h>

#define UART_TXFIFO     0
#define UART_RXFIFO     4
#define UART_TXCTRL     8
#define UART_RXCTRL     12

struct uart_port {
        void __iomem *membase;
        struct console console;
};

static int uart_in(struct uart_port *port, int offset)
{
        return readl(port->membase + offset);
}

static void uart_out(struct uart_port *port, int offset, uint8_t value)
{
        writel(value, port->membase + offset);
}

static int uart_getchar(struct console *con)
{
        struct uart_port *port = container_of(con, struct uart_port, console);
        int c;

        c = uart_in(port, UART_RXFIFO);
        if (c < 0)
                return -EAGAIN;

        return c;
}

static void uart_putchar(struct console *con, int c)
{
        struct uart_port *port = container_of(con, struct uart_port, console);

        while (uart_in(port, UART_TXFIFO) < 0)
                cpu_relax();

        uart_out(port, UART_TXFIFO, c);
}

static void init_port(struct uart_port *port)
{
        uart_out(port, UART_TXCTRL, 1);
        uart_out(port, UART_RXCTRL, 1);
}

void sifive_init(void)
{
        /* there are two serial ports on hifive boards */
        static struct uart_port ports[2];
        struct device_node *np = NULL;
        size_t i;

        for (i = 0; i < ARRAY_SIZE(ports); ++i) {
                struct uart_port *port = &ports[i];
                const be32_t *cell;

                np = of_find_compatible_node(np, NULL, "sifive,uart0");
                if (!np)
                        break;
                cell = of_get_property(np, "reg", NULL);
                if (!cell)
                        continue;

                port->membase = (void *)(uintptr_t)of_read_number(cell, of_n_addr_cells(np));
                port->console.getchar = uart_getchar;
                port->console.putchar = uart_putchar;
                init_port(port);
                register_console(&port->console);
        }
}
