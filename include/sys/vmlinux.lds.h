#pragma once

#include <io/sizes.h>

#define __VMLINUX_SYMBOL(x)     x
#define __VMLINUX_SYMBOL_STR(x) #x

/* Indirect, so macros are expanded before pasting. */
#define VMLINUX_SYMBOL(x)       __VMLINUX_SYMBOL(x)
#define VMLINUX_SYMBOL_STR(x)   __VMLINUX_SYMBOL_STR(x)

/* Align . to a 8 byte boundary equals to maximum function alignment. */
#define ALIGN_FUNCTION()        . = ALIGN(8)

#define TEXT_SECTION                                                    \
        .text : {                                                       \
                 *(.head.text)                                          \
                ALIGN_FUNCTION();                                       \
                *(.text .text.*)                                        \
                *(.fixup)                                               \
        }

#define RO_DATA_SECTION(align)                                          \
        . = ALIGN(align);                                               \
        .rodata : {                                                     \
                *(.rodata .rodata.*)                                    \
        }

#define RW_DATA_SECTION(align)                                          \
        . = ALIGN(align);                                               \
        .data : {                                                       \
                *(.data .data.*)                                        \
        }

#define BSS_SECTION(bss_align, stop_align)                              \
        . = ALIGN(bss_align);                                           \
        __bss_start = .;                                                \
        .bss : {                                                        \
                *(.bss .bss.* .sbss .sbss.*)                            \
        }                                                               \
        . = ALIGN(stop_align);                                          \
        __bss_end = .;
