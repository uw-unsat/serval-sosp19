#include <asm/sbi.h>

void __weak shutdown(void)
{
        sbi_shutdown();
        while (1)
                ;
}
