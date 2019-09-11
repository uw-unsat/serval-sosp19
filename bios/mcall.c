#include <asm/page.h>
#include <asm/mcall.h>
#include <asm/sbi.h>
#include <sys/console.h>
#include <sys/errno.h>
#include <sys/init.h>
#include <sys/memblock.h>
#include <sys/of.h>
#include <sys/sections.h>

phys_addr_t kernel_dtb;

#if !IS_ENABLED(CONFIG_VERIFICATION)

void mcall_console_putchar(uint8_t c)
{
        console_putchar(c);
}

long mcall_console_getchar(void)
{
        return console_getchar();
}

noreturn void mcall_shutdown(void)
{
        shutdown();
}

void mcall_init(phys_addr_t dtb)
{
        size_t size;

        early_init_dt_verify(__va(dtb));
        htif_init();
        uart8250_init();
        sifive_init();

        early_init_dt_scan_nodes();
        memblock_reserve(__pa(_start), _end - _start);
        memblock_reserve(__pa(_payload_start), _payload_end - _payload_start);

        /*
         * Make a copy of the DTB so that the kernel can access it.
         * Note that the kernel only maps memory from its _start up;
         * the kernel can read the new DTB because the DTB is after
         * the payload.  Also, there is no need to shrink or reserve
         * the memory size in the new DTB, as the kernel will not
         * access memory before its _start.
         */
        size = of_get_flat_dt_size();
        kernel_dtb = memblock_alloc(size, SZ_4K);
        of_dt_move(__va(kernel_dtb), size);

        memblock_dump_all();
}

#else   /* IS_ENABLED(CONFIG_VERIFICATION) */

extern volatile uint64_t tohost;

void mcall_console_putchar(uint8_t c)
{
        tohost = (UINT64_C(1) << 56) | (UINT64_C(1) << 48) | c;
}

long mcall_console_getchar(void)
{
        /* FIXME */
        return -ENOSYS;
}

noreturn void mcall_shutdown(void)
{
        tohost = 1;
        unreachable();
}

void mcall_init(phys_addr_t dtb)
{
}

#endif  /* !IS_ENABLED(CONFIG_VERIFICATION) */

long do_mcall(struct pt_regs *regs)
{
        unsigned long nr = regs->a7;
        long r = -ENOSYS;

        switch (nr) {
        default:
                pr_warn("unknown sbi call: %lu\n", nr);
                break;
        case SBI_CONSOLE_PUTCHAR:
                mcall_console_putchar(regs->a0);
                r = 0;
                break;
        case SBI_CONSOLE_GETCHAR:
                r = mcall_console_getchar();
                break;
        case SBI_SHUTDOWN:
                mcall_shutdown();
                break;
        };

        return r;
}
