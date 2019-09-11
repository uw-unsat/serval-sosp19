#include <asm/csr.h>
#include <io/asm.h>
#include "test.h"

static void __naked test_rdcycle(void)
{
        asm volatile (
                "1: \n\t"
                "rdcycle t0 \n\t"
                "li a7, 8 \n\t"
                "ecall \n\t"
                "wfi \n\t"
                "j 1b \n\t"
        );
}

static void setup(struct test *test, unsigned long mode, unsigned long mcounteren, unsigned long scounteren)
{
        struct pt_regs regs = { 0 };

        /* delegation off */
        csr_write(medeleg, 0);
        csr_write(mideleg, 0);
        /* paging off */
        csr_write(satp, SATP_MODE_BARE);

        csr_write(mstatus, mode | SR_SXL_64 | SR_UXL_64);
        csr_write(mcounteren, mcounteren);
        csr_write(scounteren, scounteren);

        test_run_guest(&regs, test_rdcycle);
}

/* supervisor */

static int supervisor_mcounteren_on(struct test *test)
{
        setup(test, SR_MPP_S, ~0ul, 0);
        ASSERT_EQ(EXC_ECALL_S, csr_read(mcause));
        return 0;
}

static int supervisor_mcounteren_off(struct test *test)
{
        setup(test, SR_MPP_S, 0, 0);
        ASSERT_EQ(EXC_ILLEGAL_INST, csr_read(mcause));
        return 0;
}

/* user */

static int user_mcounteren_on_scounteren_on(struct test *test)
{
        setup(test, SR_MPP_U, ~0ul, ~0ul);
        ASSERT_EQ(EXC_ECALL_U, csr_read(mcause));
        return 0;
}

static int user_mcounteren_on_scounteren_off(struct test *test)
{
        setup(test, SR_MPP_U, ~0ul, 0);
        ASSERT_EQ(EXC_ILLEGAL_INST, csr_read(mcause));
        return 0;
}

static int user_mcounteren_off_scounteren_on(struct test *test)
{
        setup(test, SR_MPP_U, 0, ~0ul);
        ASSERT_EQ(EXC_ILLEGAL_INST, csr_read(mcause));
        return 0;
}

static int user_mcounteren_off_scounteren_off(struct test *test)
{
        setup(test, SR_MPP_U, 0, 0);
        ASSERT_EQ(EXC_ILLEGAL_INST, csr_read(mcause));
        return 0;
}

static struct test tests[] = {
        TEST(supervisor_mcounteren_on),
        TEST(supervisor_mcounteren_off),
        TEST(user_mcounteren_on_scounteren_on),
        TEST(user_mcounteren_on_scounteren_off),
        TEST(user_mcounteren_off_scounteren_on),
        TEST(user_mcounteren_off_scounteren_off),
};

struct test_suite counteren_test = {
        .name = "counteren_test",
        .count = ARRAY_SIZE(tests),
        .tests = tests,
};
