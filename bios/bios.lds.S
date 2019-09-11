#include <asm/cache.h>
#include <asm/setup.h>
#include <sys/vmlinux.lds.h>

OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
        . = DRAM_START;

        _stext = .;
        TEXT_SECTION
        _etext = .;

        _sdata = .;
        RO_DATA_SECTION(L1_CACHE_BYTES)
        . = ALIGN(SZ_4K);
        .htif : {
               *(.htif .htif.*)
        }
        RW_DATA_SECTION(SZ_4K)
        _edata = .;

        BSS_SECTION(SZ_4K, SZ_2M)
        _end = .;

        .payload : {
                *(.payload)
        }
}
