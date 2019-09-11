xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxw r0, [r6+4]
mov32 r2, 0xc000003e
jeq r0, r2, +2
mov32 r0, 0x0
exit
ldxw r0, [r6]
jne r0, 0x2, +2
mov32 r0, 0x5000d
exit
jne r0, 0x27, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x60, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe4, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xc9, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x0, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x1, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x3, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x30, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xc, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x7, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x17, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x1c, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x9, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xb, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe7, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe, +2
mov32 r0, 0x7fff0000
exit
mov32 r0, 0x0
exit
