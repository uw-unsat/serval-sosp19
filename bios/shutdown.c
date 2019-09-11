#include <asm/io.h>
#include <asm/processor.h>
#include <sys/of.h>

void htif_shutdown(void);

void test_shutdown(void)
{
        struct device_node *np;
        const be32_t *cell;
        void __iomem *membase;

        np = of_find_node_by_path("/test");
        if (!np)
                return;

        cell = of_get_property(np, "reg", NULL);
        if (!cell)
                return;

        membase = (void *)(uintptr_t)of_read_number(cell, of_n_addr_cells(np));
        writel(0x5555, membase);
}

void shutdown(void)
{
        htif_shutdown();
        test_shutdown();
        while (1)
                wait_for_interrupt();
}
