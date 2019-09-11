#define pr_fmt(fmt)     "komodo: " fmt

#include <asm/processor.h>
#include <asm/sbi.h>
#include <sys/console.h>
#include <sys/errno.h>
#include <sys/init.h>
#include <sys/pfn.h>
#include <sys/sections.h>
#include <sys/string.h>
#include <sys/timex.h>
#include <uapi/komodo/smcapi.h>

#define ITER            200
#define ENTRYPOINT      0x8000

extern char test_enclave[], test_enclave_end[];

static char test_shared[SZ_4K] __aligned(SZ_4K);

static long g_npages;
static void driver_init(void);

noreturn void main(unsigned int hartid, phys_addr_t dtb)
{
        sbi_console_init(BRIGHT_MAGENTA);

        driver_init();

        sbi_shutdown();
        for (;;)
                wait_for_interrupt();
}

static void calibrate(void)
{
        cycles_t s0, s1, total = 0;
        int i;

        for (i = 0; i < ITER; i++) {
            s0 = get_cycles();
            s1 = get_cycles();
            total += s1-s0;
        }
        pr_info("approx cycle counter overhead is %lu/%u cycles\n",
                total, ITER);

        s0 = get_cycles();
        for (i = 0; i < ITER; i++)
                kom_smc_get_phys_pages();
        s1 = get_cycles();
        pr_info("%u iterations of a null SMC took %lu cycles\n",
                ITER, s1-s0);
}

static long pgalloc_alloc(void)
{
        static long next;

        BUG_ON(next >= g_npages);
        return next++;
}

static int test(void)
{
        int r = 0;
        kom_err_t err;
        kom_multival_t ret;
        long addrspace = -1, l1pt = -1, l2pt = -1, l3pt = -1, disp = -1, code = -1, data = -1;

        calibrate();

        addrspace = pgalloc_alloc();
        l1pt = pgalloc_alloc();
        l2pt = pgalloc_alloc();
        l3pt = pgalloc_alloc();
        disp = pgalloc_alloc();
        code = pgalloc_alloc();
        data = pgalloc_alloc();

        err = kom_smc_init_addrspace(addrspace, l1pt);
        pr_info("init_addrspace: %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        err = kom_smc_init_dispatcher(disp, addrspace, ENTRYPOINT);
        pr_info("init_dispatcher: %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        err = kom_smc_init_l2ptable(l2pt, l1pt, 0);
        pr_info("init_l2table: %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        err = kom_smc_init_l3ptable(l3pt, l2pt, 0);
        pr_info("init_l3table: %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        /* Populate the page with our test code! */
        memcpy(test_shared, test_enclave, test_enclave_end - test_enclave);

        err = kom_smc_map_secure(code, l3pt, ENTRYPOINT / PAGE_SIZE,
                                 KOM_MAPPING_R | KOM_MAPPING_X,
                                 PFN_DOWN(test_shared - _start));
        pr_info("map_secure (code): %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        memset(test_shared, 0, SZ_4K);

        err = kom_smc_map_secure(data, l3pt, ENTRYPOINT / PAGE_SIZE + 1,
                                 KOM_MAPPING_R | KOM_MAPPING_W,
                                 PFN_DOWN(test_shared - _start));
        pr_info("map_secure (data): %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        err = kom_smc_map_insecure(l3pt, ENTRYPOINT / PAGE_SIZE + 2,
                                   KOM_MAPPING_R | KOM_MAPPING_W,
                                   PFN_DOWN(test_shared - _start));
        pr_info("map_insecure: %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        err = kom_smc_finalise(addrspace);
        pr_info("finalise: %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        ret = kom_smc_execute(disp, 0, 1, 2);
        pr_info("enter: %ld 0x%lx\n", ret.err, ret.val);
        if (ret.err != KOM_ERR_SUCCESS) {
                r = -EIO;
                goto cleanup;
        }

        pr_info("wrote: %u\n", *(uint32_t *)test_shared);

cleanup:
        err = kom_smc_stop(addrspace);
        pr_info("stop: %ld\n", err);
        if (err != KOM_ERR_SUCCESS) {
                r = -EIO;
        }

        if (disp != -1) {
                err = kom_smc_remove(disp);
                pr_info("remove: %ld\n", err);
        }

        if (code != -1) {
                err = kom_smc_remove(code);
                pr_info("remove: %ld\n", err);
        }

        if (data != -1) {
                err = kom_smc_remove(data);
                pr_info("remove: %ld\n", err);
        }

        if (l3pt != -1) {
                err = kom_smc_remove(l3pt);
                pr_info("remove: %ld\n", err);
        }

        if (l2pt != -1) {
                err = kom_smc_remove(l2pt);
                pr_info("remove: %ld\n", err);
        }


        if (l1pt != -1) {
                err = kom_smc_remove(l1pt);
                pr_info("remove: %ld\n", err);
        }

        if (addrspace != -1) {
                err = kom_smc_remove(addrspace);
                pr_info("remove: %ld\n", err);
        }

        return r;
}

static void driver_init(void)
{
        long magic;
        int r;

        pr_info("driver init\n");

        magic = kom_smc_query();
        BUG_ON(magic != KOM_MAGIC);

        g_npages = kom_smc_get_phys_pages();
        pr_info("%lu pages available\n", g_npages);

        pr_info("running tests\n");
        r = test();
        pr_info("test complete: %d\n", r);
        BUG_ON(r);
}
