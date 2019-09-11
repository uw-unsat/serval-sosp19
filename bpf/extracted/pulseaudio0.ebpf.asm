xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxdw r8, [r6+216]
ldxw r9, [r6+128]
ldxw r2, [r6+132]
sub32 r9, r2
mov r2, r9
sub r2, 0x8
jslt r2, 0x4, +3
ldxw r0, [r8+8]
be32 r0
ja +8
mov r1, r6
mov r2, r8
mov r3, r9
mov r4, 0x8
call 0x702f50
jsge r0, 0x0, +2
xor32 r0, r0
exit
mov32 r2, 0xfeedcafe
jeq r0, r2, +2
mov32 r0, 0xffffffff
exit
mov r2, r9
sub r2, 0x18
jslt r2, 0x4, +3
ldxw r0, [r8+24]
be32 r0
ja +8
mov r1, r6
mov r2, r8
mov r3, r9
mov r4, 0x18
call 0x702f50
jsge r0, 0x0, +2
xor32 r0, r0
exit
mov32 r2, 0xd196ab6e
jne r0, r2, +2
mov32 r0, 0xffffffff
exit
mov32 r0, 0x0
exit
mov32 r0, 0xffffffff
exit
