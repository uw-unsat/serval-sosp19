xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxw r0, [r6+4]
mov32 r2, 0xc000003e
jeq r0, r2, +2
mov32 r0, 0x0
exit
ldxw r0, [r6]
jne r0, 0xf, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xba, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe7, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x3c, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x0, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x1, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xc, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x9, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xb, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xa, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x11, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x12, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x9a, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x38, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x49, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x111, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x35, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x3, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x20, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x21, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xd, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xca, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe5, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x23, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xc9, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x64, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe4, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x60, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x5, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x4, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x2e, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x2f, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x83, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x1c, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x3c, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x18, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xcc, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xea, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe, +2
mov32 r0, 0x7fff0000
exit
mov32 r0, 0x30000
exit
