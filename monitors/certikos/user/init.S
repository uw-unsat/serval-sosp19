#include <io/linkage.h>
#include <io/sizes.h>

#define STACK_SIZE      SZ_4K

        .section .text
/*
 * a0: file id
 * a1: start address
 */
ENTRY(_start)
        /* set up stack */
        li      a2, STACK_SIZE
        add     sp, a1, a2
        tail    load_elf
ENDPROC(_start)

#define ELF_TABLE_ENTRY(name) \
        .long   _binary_##name##_start - elf_table

#define FILE(name) \
        .balign 4; \
        _binary_##name##_start: \
        .incbin #name \

        .section .rodata
        .balign 4
GLOBAL(elf_table)
        ELF_TABLE_ENTRY(idle)
        ELF_TABLE_ENTRY(alice)
        ELF_TABLE_ENTRY(hacker)
        ELF_TABLE_ENTRY(bob)

        FILE(idle)
        FILE(alice)
        FILE(hacker)
        FILE(bob)
