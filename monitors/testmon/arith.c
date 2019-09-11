#include "test.h"

static unsigned long asm_addi(unsigned long a, unsigned long b)
{
        unsigned long result;

        asm volatile (
                "addi %0, %1, %2"
                : "=r" (result)
                : "r" (a), "i" (b)
        );
        return result;
}

static int addi(struct test *test)
{
        ASSERT_EQ(UINT64_C(0x80000000), asm_addi(INT32_MAX, 1));
        ASSERT_EQ(UINT64_C(0x80000000), asm_addi(0x80000000, 0));
        return 0;
}

static uint64_t asm_addiw(uint64_t a, uint64_t b)
{
        uint64_t result;

        asm volatile (
                "addiw %0, %1, %2"
                : "=r" (result)
                : "r" (a), "i" (b)
        );
        return result;
}

static int addiw(struct test *test)
{
        ASSERT_EQ(UINT64_C(0xffffffff80000000), asm_addiw(INT32_MAX, 1));
        ASSERT_EQ(UINT64_C(0xffffffff80000000), asm_addiw(0x80000000, 0));
        return 0;
}

static struct test tests[] = {
        TEST(addi),
        TEST(addiw),
};

struct test_suite arith_test = {
        .name = "arith_test",
        .count = ARRAY_SIZE(tests),
        .tests = tests,
};
