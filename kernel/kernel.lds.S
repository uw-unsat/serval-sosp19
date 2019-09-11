#include <asm/cache.h>
#include <asm/setup.h>
#include <sys/vmlinux.lds.h>

OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
        . = KERNEL_VIRTUAL_START;

        _stext = .;
        TEXT_SECTION
        _etext = .;

        _sdata = .;
        RO_DATA_SECTION(SZ_4K)
        RW_DATA_SECTION(SZ_4K)
        _edata = .;

        BSS_SECTION(SZ_4K, SZ_4K)
        _end = .;
}
