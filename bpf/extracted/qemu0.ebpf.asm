xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxw r0, [r6+4]
mov32 r2, 0xc000003e
jne r0, r2, +55
ldxw r0, [r6]
jlt r0, 0x40000000, +2
mov32 r2, 0xffffffff
jne r0, r2, +51
jeq r0, 0x67, +48
jeq r0, 0x86, +47
jeq r0, 0x88, +46
jeq r0, 0x8b, +45
jeq r0, 0x9c, +44
jeq r0, 0xa5, +43
jeq r0, 0xa7, +42
jeq r0, 0xa8, +41
jeq r0, 0xa9, +40
jeq r0, 0xae, +39
jeq r0, 0xb1, +38
jeq r0, 0xb2, +37
jeq r0, 0xb5, +36
jeq r0, 0xb6, +35
jeq r0, 0xb7, +34
jeq r0, 0xb8, +33
jeq r0, 0xb9, +32
jeq r0, 0xec, +31
jeq r0, 0xf6, +30
mov32 r2, 0xffffd8aa
jeq r0, r2, +28
mov32 r2, 0xffffd8ab
jeq r0, r2, +26
mov32 r2, 0xffffd8af
jeq r0, r2, +24
mov32 r2, 0xffffd8b3
jeq r0, r2, +22
mov32 r2, 0xffffd8bb
jeq r0, r2, +20
mov32 r2, 0xffffd8c7
jeq r0, r2, +18
mov32 r2, 0xffffd8c8
jeq r0, r2, +16
mov32 r2, 0xffffd8c9
jeq r0, r2, +14
mov32 r2, 0xffffd8d2
jeq r0, r2, +12
mov32 r2, 0xffffd8d5
jeq r0, r2, +10
mov32 r2, 0xffffd8da
jeq r0, r2, +8
mov32 r2, 0xffffd8e3
jeq r0, r2, +6
mov32 r2, 0xffffd8ed
jeq r0, r2, +4
mov32 r2, 0xffffd8ee
jeq r0, r2, +2
mov32 r0, 0x7fff0000
exit
mov32 r0, 0x30000
exit
mov32 r0, 0x0
exit
