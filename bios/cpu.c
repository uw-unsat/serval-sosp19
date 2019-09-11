#include <asm/csr.h>
#include <sys/types.h>

void cpu_info(void)
{
        unsigned long hartid, vendorid, archid, impid, misa;
        char extensions[26 + 1];
        size_t i;

        hartid = csr_read(mhartid);
        vendorid = csr_read(mvendorid);
        archid = csr_read(marchid);
        impid = csr_read(mimpid);
        misa = csr_read(misa);

        for (i = 0; i < 26; ++i)
                extensions[i] = (misa & (1 << i)) ? ('A' + i) : '-';
        extensions[26] = 0;

        pr_info("mhartid    = %lu\n"
                "mvendorid  = 0x%016lx\n"
                "marchid    = 0x%016lx\n"
                "mimpid     = 0x%016lx\n"
                "misa       = 0x%016lx\n"
                "extensions = %s\n\n",
                hartid, vendorid, archid, impid, misa, extensions);
}
