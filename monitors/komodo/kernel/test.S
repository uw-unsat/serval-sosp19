#include <io/linkage.h>
#include <io/sizes.h>
#include <uapi/komodo/svccalls.h>

        .section .text

        .balign 4
ENTRY(test_enclave)
#if 0
        // trivial test code
    "   mov     r1, #42                         \n"
    "   mov     r2, #0xa000                     \n"
    "   str     r1, [r2]                        \n"
        // grab cycles for later
    "   mrc     p15, 0, r9, c9, c13, 0          \n"
    "   cmp     r0, #0                          \n"
    "   beq     9f                              \n"
    "   cmp     r0, #1                          \n"
    "   beq     2f                              \n"
    "   cmp     r0, #2                          \n"
    "   beq     3f                              \n"
    "   cmp     r0, #3                          \n"
    "   beq     4f                              \n"
    "   cmp     r0, #4                          \n"
    "   beq     5f                              \n"
#endif
        li      t1, 42
        li      t2, 0xa000
        sd      t1, 0(t2)
        beqz    a0, 9f
        li      t0, 1
        beq     a0, t0, 2f
        li      t0, 2
        beq     a0, t0, 3f
        li      t0, 3
        beq     a0, t0, 4f
        li      t0, 4
        beq     a0, t0, 5f

#if 0
    // straight exit
    "9: mov     r1, r9                          \n" // cycle count
    "1: mov     r0, #0                          \n" // KOM_SVC_EXIT
    "   svc     #0                              \n"
    "   b       1b                              \n"
#endif
9:
1:
        li      a7, KOM_SVC_EXIT
        ecall
        j       1b

#if 0
    // enter/resume tests: exec until interrupted
    "2: mov     r2, r9                          \n"
    "   mrc     p15, 0, r9, c9, c13, 0          \n" // while (1) {
    "   sub     r3, r9, r2                      \n" // delta = rdcycles() - oldcycles;
    "   cmp     r3, #200                        \n" // if (delta > 200) break;
    "   bgt     9b                              \n"
    "   b       2b 
#endif
2:
        /* TODO */
        j       2b

#if 0
    // attest test
    "3: mov     r0, #1                          \n" // KOM_SVC_ATTEST
    "   mrc     p15, 0, r9, c9, c13, 0          \n" // r9 = start
    "   svc     #0                              \n"
    "   mrc     p15, 0, r10, c9, c13, 0         \n" // r10 = end
    "   sub     r1, r10, r9                     \n" // retval = end - start
    "   b       1b                              \n" // exit
#endif
3:
        /* TODO */
        j       1b

#if 0
    // verify test
    "4: mov     r0, #2                          \n" // KOM_SVC_VERIFY_STEP0
    "   mrc     p15, 0, r9, c9, c13, 0          \n" // r9 = start
    "   svc     #0                              \n"
    "   mov     r0, #3                          \n" // KOM_SVC_VERIFY_STEP1
    "   svc     #0                              \n"
    "   mov     r0, #4                          \n" // KOM_SVC_VERIFY_STEP2
    "   svc     #0                              \n"
    "   mrc     p15, 0, r10, c9, c13, 0         \n" // r10 = end
    "   sub     r1, r10, r9                     \n" // retval = end - start
    "   b       1b 
#endif
4:
        /* TODO */
        j       1b

#if 0
    // map_data test
    "5: mov     r0, #10                         \n" // KOM_SVC_MAP_DATA
    // r1 = pageno, r2 = mapping
    "   mov     r11, r1                         \n" // save pageno (from SVC args) for later
    "   movw    r2, #0xd003                     \n" // RW page at 0xd000
    "   mrc     p15, 0, r9, c9, c13, 0          \n" // r9 = start
    "   svc     #0                              \n"
    "   mrc     p15, 0, r10, c9, c13, 0         \n" // r10 = end
    "   cmp     r0, #0                          \n" // bail on failure
    "   bne     6f                              \n"
    "   mov     r0, #11                         \n" // KOM_SVC_UNMAP_DATA
    "   mov     r1, r11                         \n" //pageno
    "   movw    r2, #0xd003                     \n" // map VA
    "   svc     #0                              \n"
    "   cmp     r0, #0                          \n" // bail on failure
    "   bne     7f                              \n"
    "   sub     r1, r10, r9                     \n" // retval = end - start
    "   b       1b                              \n" // exit
    "6: mov     r1, r0                          \n" // fail case 1
    "   b       1b                              \n"
    "7: add     r1, r0, #30                     \n" // fail case 2
    "   b       1b  
#endif
5:
        /* TODO */
        j       1b

ENTRY(test_enclave_end)
