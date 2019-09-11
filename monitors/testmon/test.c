#include <io/linkage.h>
#include <sys/console.h>
#include <sys/list.h>
#include <sys/timex.h>
#include "test.h"

#define pr_succ(prefix, fmt, ...) \
        printk(LOGLEVEL_EMERG, BRIGHT_GREEN prefix RESET_COLOR " " pr_fmt(fmt), ##__VA_ARGS__)

#define pr_fail(prefix, fmt, ...) \
        printk(LOGLEVEL_EMERG, BRIGHT_RED prefix RESET_COLOR " " pr_fmt(fmt), ##__VA_ARGS__)

static LIST_HEAD(suites);
static size_t nr_suites, nr_tests;

asmlinkage void test_enter(struct pt_regs *regs);
asmlinkage void test_exit(void);

void test_register(struct test_suite *suite)
{
        list_add_tail(&suite->list, &suites);
        ++nr_suites;
        nr_tests += suite->count;
}

static const char *plural(size_t n)
{
        return (n == 1) ? "" : "s";
}

void test_run(void)
{
        struct test_suite *suite;
        struct test *test;
        unsigned long delta_total = 0;
        size_t nr_passed = 0, nr_failed = 0;
        LIST_HEAD(failed_tests);

        pr_succ("[==========]", "Running %zu test%s from %zu test suite%s.\n",
                nr_tests, plural(nr_tests), nr_suites, plural(nr_suites));

        list_for_each_entry(suite, &suites, list) {
                unsigned long delta_suite = 0;
                size_t i, n = suite->count;
                test = suite->tests;

                pr_succ("[----------]", "%zu test%s from %s\n", n, plural(n), suite->name);
                for (i = 0; i < n; ++i, ++test) {
                        unsigned long tic, tac, delta;
                        int r;

                        pr_succ("[ RUN      ]", "%s.%s\n", suite->name, test->name);
                        tic = get_cycles();
                        r = test->run(test);
                        tac = get_cycles();
                        delta = tac - tic;
                        delta_suite += delta;
                        if (r) {
                                ++nr_failed;
                                pr_fail("[  FAILED  ]", "%s.%s (%lu cycles)\n",
                                        suite->name, test->name, delta);
                                test->suite = suite;
                                list_add_tail(&test->list, &failed_tests);
                        } else {
                                ++nr_passed;
                                pr_succ("[  PASSED  ]", "%s.%s (%lu cycles)\n",
                                        suite->name, test->name, delta);
                        }
                }

                delta_total += delta_suite;
                pr_succ("[----------]", "%s (%lu cycles total)\n\n", suite->name, delta_suite);
        }

        pr_succ("[==========]", "%zu test%s from %zu test suite%s ran. (%lu cycles total)\n",
                nr_tests, plural(nr_tests), nr_suites, plural(nr_suites), delta_total);

        pr_succ("[  PASSED  ]", "%zu test%s.\n", nr_passed, plural(nr_passed));

        if (!nr_failed)
                return;
        pr_fail("[  FAILED  ]", "%zu test%s, listed below:\n", nr_failed, plural(nr_failed));
        list_for_each_entry(test, &failed_tests, list) {
                pr_fail("[  FAILED  ]", "%s.%s\n", test->suite->name, test->name);
        }
}

void test_run_guest(struct pt_regs *regs, void *mepc)
{
        unsigned long mtvec, mscratch;

        /* save mtvec & mscratch */
        mtvec = csr_read(mtvec);
        mscratch = csr_read(mscratch);

        csr_write(mepc, mepc);
        csr_write(mtvec, test_exit);
        test_enter(regs);

        /* restore mtvec & mscratch */
        csr_write(mtvec, mtvec);
        csr_write(mscratch, mscratch);
}
