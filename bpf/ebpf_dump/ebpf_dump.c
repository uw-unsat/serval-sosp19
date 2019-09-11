#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kprobes.h>
#include <linux/filter.h>
#include <linux/spinlock.h>
#include <linux/pid.h>
#include <linux/sched.h>

static spinlock_t dump_lock;

static struct bpf_prog *j_bpf_int_jit_compile(struct bpf_prog *prog)
{
	static char prefix[32];

	spin_lock(&dump_lock);

	pr_info("kprobe: prog = 0x%p\n", prog);
	pr_info("bpf_prog_type = %d\n", prog->type);
	pr_info("proc name = %s\n", current->comm);
	pr_info("proc id = %d\n", (int) task_pid_nr(current));

	snprintf(prefix, ARRAY_SIZE(prefix), "ebpf [%s]: ", current->comm);
	print_hex_dump(KERN_ERR, prefix, DUMP_PREFIX_OFFSET, 8, 1,
		prog->insns, prog->len * 8, false);

	pr_info("Done printing\n");

	spin_unlock(&dump_lock);

	return NULL;
}

static int pre_handler(struct kprobe *kp, struct pt_regs *regs)
{
	j_bpf_int_jit_compile((struct bpf_prog *) regs->di);
	return 0;
}

static struct kprobe bpf_int_jit_compile_kprobe = {
	.pre_handler 	= &pre_handler,
    .symbol_name    = "bpf_int_jit_compile",
};

static int __init kprobe_init(void)
{
    int ret;

	spin_lock_init(&dump_lock);

    ret = register_kprobe(&bpf_int_jit_compile_kprobe);
    if (ret < 0) {
        pr_err("register_kprobe failed, returned %d\n", ret);
        return -1;
    }


    return 0;
}

static void __exit kprobe_exit(void)
{
    unregister_kprobe(&bpf_int_jit_compile_kprobe);
}

module_init(kprobe_init);
module_exit(kprobe_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Luke Nelson <luke.r.nels@gmail.com>");

