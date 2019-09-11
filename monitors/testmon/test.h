#pragma once

#include <asm/ptrace.h>
#include <sys/console.h>

#define pr_test(fmt, ...) \
        printk(LOGLEVEL_EMERG, pr_fmt(fmt), ##__VA_ARGS__)

#define TEST(f)         { #f, f }

#define ASSERT_EQ(expected, actual)                                     \
({                                                                      \
        unsigned long long _exp = (unsigned long long)(expected);       \
        unsigned long long _act = (unsigned long long)(actual);         \
        if (_exp != _act) {                                             \
                pr_test("%s:%d: Failure\n"                              \
                        "Value of: %s\n"                                \
                        "Expected: 0x%llx\n"                            \
                        "  Actual: 0x%llx\n",                           \
                        __FILE__, __LINE__, #actual, _exp, _act);       \
                return -1;                                              \
        }                                                               \
})

struct test;

struct test_suite {
        const char *name;
        size_t count;
        struct test *tests;
        struct list_head list;
};

struct test {
        const char *name;
        int (*run)(struct test *);
        struct test_suite *suite;
        struct list_head list;  /* for failed */
};

extern struct test_suite *suites_start[], *suites_end[];

void test_run_guest(struct pt_regs *regs, void *mepc);

void test_register(struct test_suite *suite);
void test_run(void);
