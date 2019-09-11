        .section ".payload","a",@progbits

.globl _payload_start, _payload_end
        .p2align 21     /* 2M */
_payload_start:
        .incbin BBL_PAYLOAD
        .p2align 12     /* 4K */
_payload_end:
