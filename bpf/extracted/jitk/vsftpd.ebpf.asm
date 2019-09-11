xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxw r0, [r6+4]
mov32 r2, 0xc000003e
jeq r0, r2, +2
mov32 r0, 0x0
exit
ldxw r0, [r6]
jne r0, 0x0, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x1, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x9, +7
ldxw r0, [r6+40]
jne r0, 0x22, +4
ldxw r0, [r6+32]
jne r0, 0x3, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6]
jne r0, 0xa, +6
ldxw r0, [r6+32]
mov32 r2, 0xfffffffe
jset r0, r2, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6]
jne r0, 0xb, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xc, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x19, +2
mov32 r0, 0x50026
exit
jne r0, 0xf, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xdb, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x3, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0xe7, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x2d, +5
ldxw r0, [r6+40]
jne r0, 0x2, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6]
jne r0, 0x23, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x27, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x30, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x48, +5
ldxw r0, [r6+24]
jne r0, 0x3, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6]
jne r0, 0x48, +8
ldxw r0, [r6+24]
jne r0, 0x4, +5
ldxw r0, [r6+32]
mov32 r2, 0xfff6733c
jset r0, r2, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6]
jne r0, 0xd, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x25, +2
mov32 r0, 0x7fff0000
exit
jne r0, 0x48, +5
ldxw r0, [r6+24]
jne r0, 0x7, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6]
jne r0, 0x48, +5
ldxw r0, [r6+24]
jne r0, 0x6, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6]
mov32 r0, 0x0
exit
