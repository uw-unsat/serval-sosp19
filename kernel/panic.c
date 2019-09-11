#include <sys/bug.h>
#include <sys/printk.h>

void panic(const char *fmt, ...)
{
        static char buf[1024];
        va_list args;

        va_start(args, fmt);
        vsnprintf(buf, sizeof(buf), fmt, args);
        va_end(args);
        pr_emerg("panic: %s", buf);

        dump_stack();
        shutdown();
}

void die(struct pt_regs *regs, const char *str)
{
        pr_emerg("%s", str);
        show_regs(regs);

        dump_stack();
        shutdown();
}
