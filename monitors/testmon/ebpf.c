#include <asm/csr.h>
#include "test.h"

/* The filters we test for were built for the x86-64
   syscall table. If we want to test the long path in seccomp
   (i.e., an accepted system call), then we need to "fake"
   the correct data. */
#define AUDIT_ARCH_X86_64       0xC000003E

#define SECCOMP_RET_KILL_PROCESS 0x80000000U /* kill the process */
#define SECCOMP_RET_KILL_THREAD  0x00000000U /* kill the thread */
#define SECCOMP_RET_KILL     SECCOMP_RET_KILL_THREAD
#define SECCOMP_RET_ALLOW    0x7fff0000U /* allow */

struct seccomp_data {
        int nr;
        uint32_t arch;
        uint64_t instruction_pointer;
        uint64_t args[6];
};

typedef int (*seccomp_filter_t)(struct seccomp_data *);

static int run_seccomp_filter(const char *name, seccomp_filter_t filter)
{
        int retno;
        volatile uint64_t mcycle[2], minstret[2];
        struct seccomp_data data = {
                .nr = 0,
                .arch = AUDIT_ARCH_X86_64,
                .instruction_pointer = 0,
                .args = { 0 },
        };

        pr_info("Running seccomp filter %s:\n"
                "  Addr:\t0x%p\n"
                "  Data:\t0x%p\n",
                name,
                (void *) filter,
                &data);

        mcycle[0] = csr_read(mcycle);
        minstret[0] = csr_read(minstret);
        retno = filter(&data);
        minstret[1] = csr_read(minstret);
        mcycle[1] = csr_read(mcycle);

        pr_info("Ran seccomp filter %s:\n"
                "  Return value:\t0x%x\n"
                "  Cycles:\t%lu\n"
                "  Instructions:\t%lu\n\n\n",
                name,
                retno,
                mcycle[1] - mcycle[0],
                minstret[1] - minstret[0]);

        ASSERT_EQ(SECCOMP_RET_ALLOW, retno);
        return 0;
}

static int run_linux_jitk_seccomp(struct test *test)
{
        int i = 0;

        extern int linux_jitk_qemu(struct seccomp_data *);
        i |= run_seccomp_filter("linux_jitk_qemu", &linux_jitk_qemu);

        extern int linux_jitk_chrome(struct seccomp_data *);
        i |= run_seccomp_filter("linux_jitk_chrome", &linux_jitk_chrome);

        extern int linux_jitk_firefox(struct seccomp_data *);
        i |= run_seccomp_filter("linux_jitk_firefox", &linux_jitk_firefox);

        extern int linux_jitk_nacl(struct seccomp_data *);
        i |= run_seccomp_filter("linux_jitk_nacl", &linux_jitk_nacl);

        extern int linux_jitk_vsftpd(struct seccomp_data *);
        i |= run_seccomp_filter("linux_jitk_vsftpd", &linux_jitk_vsftpd);

        extern int linux_jitk_tor(struct seccomp_data *);
        i |= run_seccomp_filter("linux_jitk_tor", &linux_jitk_tor);

        extern int linux_jitk_openssh(struct seccomp_data *);
        i |= run_seccomp_filter("linux_jitk_openssh", &linux_jitk_openssh);

        return i;
}

static int run_jitsynth_jitk_seccomp(struct test *test)
{
        int i = 0;

        extern int jitsynth_jitk_qemu(struct seccomp_data *);
        i |= run_seccomp_filter("jitsynth_jitk_qemu", &jitsynth_jitk_qemu);

        extern int jitsynth_jitk_chrome(struct seccomp_data *);
        i |= run_seccomp_filter("jitsynth_jitk_chrome", &jitsynth_jitk_chrome);

        extern int jitsynth_jitk_firefox(struct seccomp_data *);
        i |= run_seccomp_filter("jitsynth_jitk_firefox", &jitsynth_jitk_firefox);

        extern int jitsynth_jitk_nacl(struct seccomp_data *);
        i |= run_seccomp_filter("jitsynth_jitk_nacl", &jitsynth_jitk_nacl);

        extern int jitsynth_jitk_vsftpd(struct seccomp_data *);
        i |= run_seccomp_filter("jitsynth_jitk_vsftpd", &jitsynth_jitk_vsftpd);

        extern int jitsynth_jitk_tor(struct seccomp_data *);
        i |= run_seccomp_filter("jitsynth_jitk_tor", &jitsynth_jitk_tor);

        extern int jitsynth_jitk_openssh(struct seccomp_data *);
        i |= run_seccomp_filter("jitsynth_jitk_openssh", &jitsynth_jitk_openssh);

        return i;
}

static struct test tests[] = {
        TEST(run_linux_jitk_seccomp),
        // TEST(run_jitsynth_jitk_seccomp),
};

struct test_suite ebpf_test = {
        .name = "ebpf_test",
        .count = ARRAY_SIZE(tests),
        .tests = tests,
};
