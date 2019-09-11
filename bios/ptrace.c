#include <asm/csr.h>

struct pt_regs *current_pt_regs(void)
{
        return (void *)(uintptr_t)csr_read(mscratch);
}
