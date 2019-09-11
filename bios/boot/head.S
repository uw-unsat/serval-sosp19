#include <asm/entry.h>
#include <asm/setup.h>
#include <asm/csr_bits/status.h>


        .section .head.text

/*
 * Upon entry:
 * - a0 is the hart ID;
 * - a1 is a pointer to the device tree blob.
 */
ENTRY(_start)

        /* Clear interrupt-pending and interrupt-enable bits */
        csrw    mip, x0
        csrw    mie, x0

        /* Clear status register */
        csrw    mstatus, x0

        /* Only boot one CPU */
        li      t0, CONFIG_BOOT_CPU
        bne     a0, t0, hartN


        /*
         * Hart IDs are not guaranteed to be contiguous.
         * For simplicity, we use hart IDs to index into cpu_stack.
         */

        /* set up the per-CPU stack */
        la      sp, cpu_stack + CPU_STACK_SIZE - PT_SIZE_ON_STACK
        slli    t0, a0, CPU_STACK_SHIFT
        add     sp, sp, t0

        /* set up trap handling */
        csrw    mscratch, sp
        la      t0, machine_trap_vector
        csrw    mtvec, t0

        /* Bring PMP into well-known state by disabling everything */
        csrw    pmpcfg0, zero
        csrw    pmpcfg2, zero
        csrw    pmpaddr0, zero
        csrw    pmpaddr1, zero
        csrw    pmpaddr2, zero
        csrw    pmpaddr3, zero
        csrw    pmpaddr4, zero
        csrw    pmpaddr5, zero
        csrw    pmpaddr6, zero
        csrw    pmpaddr7, zero
        csrw    pmpaddr8, zero
        csrw    pmpaddr9, zero
        csrw    pmpaddr10, zero
        csrw    pmpaddr11, zero
        csrw    pmpaddr12, zero
        csrw    pmpaddr13, zero
        csrw    pmpaddr14, zero
        csrw    pmpaddr15, zero
        sfence.vma

        tail    main

hartN:
        wfi
        j       hartN
END(_start)
