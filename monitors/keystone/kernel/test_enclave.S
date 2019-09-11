#include <io/sizes.h>


.balign 512
.globl enclave_code
enclave_code:
        li      sp, 0
        li      gp, 0
        li      tp, 0
        li      a4, 30
        li      a7, 12 /* exit_enclave */
        la      a0, enclave_user_code
        csrw    sepc, a0
        la      a0, enclave_trap_vector
        csrw    stvec, a0
        sret

enclave_trap_vector:
        ecall
        csrr    a0, sepc
        addi    a0, a0, 4
        csrw    sepc, a0
        sret

enclave_user_code:
     2: addi    a0, a4, 0
        slli    a4, a4, 1

  loop: addi    a0, a0, -1
        bnez    a0, loop

        ld      a0, shared_region
        addi    a0, a0, 1
        sd      a0, shared_region, a1
        ecall
        j       2b

end:

.skip (512-(end-enclave_code)), 0
