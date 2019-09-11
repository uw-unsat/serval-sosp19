#include <asm/ptrace.h>
#include <asm/setup.h>
#include <sys/sections.h>
#include <sys/types.h>

static inline int kstack_end(void *addr)
{
        /* Reliable end of stack detection:
         * Some APM bios versions misalign the stack
         */
        return !(((unsigned long)addr + sizeof(void *) - 1) &
                 (CPU_STACK_SIZE - sizeof(void *)));
}

static bool kernel_text_address(unsigned long addr)
{
        if (addr >= (unsigned long)_stext &&
            addr < (unsigned long)_etext)
                return 1;

        return 0;
}

/* assume no frame pointer */
static void walk_stackframe(bool (*fn)(unsigned long, void *), void *arg)
{
        unsigned long sp, pc;
        unsigned long *ksp;
        const register unsigned long current_sp asm("sp");

        sp = current_sp;
        pc = (uintptr_t)walk_stackframe;

        if (sp & 0x7)
                return;

        ksp = (unsigned long *)sp;
        while (!kstack_end(ksp)) {
                if (kernel_text_address(pc) && fn(pc, arg))
                        break;
                pc = (*ksp++) - 0x4;
        }
}

static bool print_trace_address(unsigned long pc, void *arg)
{
        pr_info("[<%px>]\n", (void *)pc);
        return false;
}

void dump_stack(void)
{
        pr_info("Call Trace:\n");
        walk_stackframe(print_trace_address, NULL);
}
