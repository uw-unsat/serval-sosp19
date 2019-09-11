/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#ifdef __ASSEMBLER__

#define __ALIGN         .balign 4
#define __ALIGN_STR     ".balign 4"

#define ALIGN           __ALIGN

/* Some toolchains use other characters (e.g. '`') to mark new line in macro */
#ifndef ASM_NL
#define ASM_NL          ;
#endif

#define SYSCALL_ALIAS(alias, name) \
        .globl alias; \
        .set   alias, name

#define ENTRY(name) \
        .globl name ASM_NL \
        ALIGN ASM_NL \
        name:

#define END(name) \
        .size name, .-name

/* If symbol 'name' is treated as a subroutine (gets called, and returns)
 * then please use ENDPROC to mark 'name' as STT_FUNC for the benefit of
 * static analysis tools such as stack depth analyzer.
 */
#define ENDPROC(name) \
        .type name, @function ASM_NL \
        END(name)

#define GLOBAL(name)    \
        .globl name;    \
        name:

#else   /* !__ASSEMBLER__ */

#ifdef __cplusplus
#define CPP_ASMLINKAGE  extern "C"
#else
#define CPP_ASMLINKAGE
#endif

#ifndef asmlinkage
#define asmlinkage      CPP_ASMLINKAGE
#endif

#endif  /* __ASSEMBLER__ */
