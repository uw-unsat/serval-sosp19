#include <sys/of.h>
#include <asm/sbi.h>
#include <asm/processor.h>
#include <asm/page.h>
#include <asm/csr.h>
#include <sys/console.h>
#include <sys/init.h>
#include <sys/sections.h>
#include <sys/string.h>

extern void enclave_code();

uint64_t shared_region[1];

extern long destroy_enclave();
extern long run_enclave();
extern long exit_enclave();
extern long resume_enclave();

extern long sys_create_enclave();

static uintptr_t phys_to_offset(phys_addr_t addr)
{
        return addr - __pa(_start);
}

long create_enclave(unsigned long eid, uintptr_t entry,
                    phys_addr_t secure_base, size_t secure_size,
                    phys_addr_t shared_base, size_t shared_size)
{
        return sys_create_enclave(eid, entry,
                                  phys_to_offset(secure_base),
                                  phys_to_offset(secure_base) + secure_size,
                                  phys_to_offset(shared_base),
                                  phys_to_offset(shared_base) + shared_size);
}

#define CHECK(e) BUG_ON((e) != 0)

noreturn void main(unsigned int hartid, phys_addr_t dtb)
{
        int i;
        unsigned long eid = 0;
        uint8_t c;

        sbi_console_init(BRIGHT_MAGENTA);
        pr_info("Hello from kernel!\n");

        CHECK(create_enclave(eid, __pa(enclave_code), __pa(enclave_code), 512, __pa(shared_region), 8));

        shared_region[0] = 0;

        // uint64_t last_instret = csr_read(instret);
        // uint64_t last_cycle = csr_read(cycle);

        for (i = 0; i < 4; ++i) {

                // uint64_t next_instret = csr_read(instret);
                // uint64_t next_cycle = csr_read(cycle);
                // // pr_info("instret delta = %08ld\n", next_instret - last_instret);
                // // pr_info("cycle delta = %08ld\n", next_cycle - last_cycle);
                // last_instret = next_instret;
                // last_cycle = next_cycle;

                pr_info("Entering enclave iteration %d\n", i);
                if (!i)
                        CHECK(run_enclave(eid));
                else
                        CHECK(resume_enclave(eid));
                pr_info("Returning from enclave\n");
        }
        pr_info("Destroying enclave\n");
        CHECK(destroy_enclave(eid));


        BUG_ON(shared_region[0] != 4);

        memcpy(&c, enclave_code, 1);
        BUG_ON(c != 0);

        sbi_shutdown();
        for (;;)
                wait_for_interrupt();
}
