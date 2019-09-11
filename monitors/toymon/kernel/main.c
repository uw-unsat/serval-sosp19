#include <sys/of.h>
#include <asm/sbi.h>
#include <asm/processor.h>
#include <asm/page.h>
#include <asm/csr.h>
#include <sys/console.h>
#include <sys/init.h>
#include <sys/sections.h>
#include <sys/string.h>

#define CHECK(e) BUG_ON((e) != 0)

extern long sys_hello_world(void);

noreturn void main(unsigned int hartid, phys_addr_t dtb)
{
        sbi_console_init(BRIGHT_MAGENTA);
        pr_info("Hello from kernel!\n");

        CHECK(sys_hello_world());

        sbi_shutdown();
        for (;;)
                wait_for_interrupt();
}
