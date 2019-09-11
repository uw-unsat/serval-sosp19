#include <asm/io.h>
#include <asm/processor.h>
#include <sys/console.h>
#include <sys/errno.h>
#include <sys/of.h>

/*
 * DLAB=0
 */
#define UART_RX         0       /* In:  Receive buffer */
#define UART_TX         0       /* Out: Transmit buffer */

#define UART_IER        1       /* Out: Interrupt Enable Register */
#define UART_IER_UUE    0x40    /* UART Unit Enable */

#define UART_LSR        5       /* In:  Line Status Register */
#define UART_LSR_TEMT           0x40 /* Transmitter empty */
#define UART_LSR_THRE           0x20 /* Transmit-hold-register empty */
#define UART_LSR_DR             0x01 /* Receiver data ready */

struct uart_port {
        void __iomem *membase;
        struct console console;
};

static int uart_in(struct uart_port *port, int offset)
{
        return readb(port->membase + offset);
}

static void uart_out(struct uart_port *port, int offset, uint8_t value)
{
        writeb(value, port->membase + offset);
}

static int uart_getchar(struct console *con)
{
        struct uart_port *port = container_of(con, struct uart_port, console);

        if (!(uart_in(port, UART_LSR) & UART_LSR_DR))
                return -EAGAIN;

        return uart_in(port, UART_RX);
}

static void uart_putchar(struct console *con, int c)
{
        struct uart_port *port = container_of(con, struct uart_port, console);
        unsigned int status, both_empty = UART_LSR_TEMT|UART_LSR_THRE;

        uart_out(port, UART_TX, c);

        for (;;) {
                status = uart_in(port, UART_LSR);
                if ((status & both_empty) == both_empty)
                        break;
                cpu_relax();
        }
}

static void init_port(struct uart_port *port)
{
        unsigned int ier;

        /* only mask interrupts; good enough for QEMU */
        ier = uart_in(port, UART_IER);
        uart_out(port, UART_IER, ier & UART_IER_UUE);
}

void uart8250_init(void)
{
        static struct uart_port port;
        struct device_node *np;
        const be32_t *cell;

        np = of_find_node_by_path("/uart");
        if (!np)
                return;

        if (!of_device_is_compatible(np, "ns16550a"))
                return;

        cell = of_get_property(np, "reg", NULL);
        if (!cell)
                return;

        port.membase = (void *)(uintptr_t)of_read_number(cell, of_n_addr_cells(np));
        port.console.getchar = uart_getchar;
        port.console.putchar = uart_putchar;
        init_port(&port);
        register_console(&port.console);
}
