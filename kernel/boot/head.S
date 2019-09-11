#include <asm/entry.h>
#include <asm/csr.h>
#include <asm/page.h>

        .section .head.text

ENTRY(_start)
        /* mask interrupts */
        csrw    sie, zero

        csrw    sstatus, zero

        /* allow one CPU to boot first */
        li      t0, CONFIG_BOOT_CPU
        bne     a0, t0, hartN

        /* save hart ID and DTB physical address */
        mv      s0, a0
        mv      s1, a1

        /* clear BSS */
        la      a0, __bss_start
        la      a1, __bss_end
bss_loop:
        REG_S   zero, 0(a0)
        addi    a0, a0, SZREG
        bltu    a0, a1, bss_loop

        /* fill kernel_gd (sp holds a physical address) */
        la      sp, cpu_stack + CPU_STACK_SIZE - PT_SIZE_ON_STACK
        call    setup_vm

        /* relocate pc and sp */
        call    relocate

        /* reload sp */
        la      sp, cpu_stack + CPU_STACK_SIZE - PT_SIZE_ON_STACK

        /* set sscratch for trap handling */
        csrw    sscratch, sp

        /* set trap vector */
        la      t0, supervisor_trap_vector
        csrw    stvec, t0

        /* start the kernel */
        mv      a0, s0
        mv      a1, s1
        tail    main

relocate:
        /* a1: va_pa_offset */
        li      a1, KERNEL_VIRTUAL_START
        la      a0, _start
        sub     a1, a1, a0

        /* relocate return address */
        add     ra, ra, a1

        /* point stvec to the VA after satp write */
        la      a0, 1f
        add     a0, a0, a1
        csrw    stvec, a0

        /* load the kernel page table */
        la      a0, kernel_pgd
        srl     a0, a0, PAGE_SHIFT
        li      a1, SATP_MODE_SV39
        or      a0, a0, a1
        sfence.vma
        csrw    satp, a0

        /* fall through if VA == PA; trap here otherwise */
1:
        ret

hartN:
        wfi
        j       hartN
END(_start)
