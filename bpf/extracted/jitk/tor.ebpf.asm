xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxw r0, [r6+4]
mov32 r2, 0xc000003e
jne r0, r2, +90
ldxw r0, [r6]
jeq r0, 0x0, +130
jeq r0, 0x1, +129
jeq r0, 0x3, +128
jeq r0, 0x4, +127
jeq r0, 0x5, +126
jeq r0, 0x8, +125
jeq r0, 0x9, +124
jeq r0, 0xb, +123
jeq r0, 0xc, +122
jeq r0, 0xf, +121
jeq r0, 0x14, +120
jeq r0, 0x15, +119
jeq r0, 0x1c, +118
jeq r0, 0x2a, +117
jeq r0, 0x2c, +116
jeq r0, 0x2d, +115
jeq r0, 0x2f, +114
jeq r0, 0x31, +113
jeq r0, 0x33, +112
jeq r0, 0x38, +111
jeq r0, 0x3c, +110
jeq r0, 0x3f, +109
jeq r0, 0x48, +108
jeq r0, 0x53, +107
jeq r0, 0x57, +106
jeq r0, 0x60, +105
jeq r0, 0x61, +104
jeq r0, 0x66, +103
jeq r0, 0x68, +102
jeq r0, 0x6b, +101
jeq r0, 0x6c, +100
jeq r0, 0x97, +99
jne r0, 0x9c, +2
mov32 r0, 0x50001
exit
jeq r0, 0xd5, +95
jeq r0, 0xd9, +94
jeq r0, 0xe4, +93
jeq r0, 0xe7, +92
jeq r0, 0xe8, +91
jeq r0, 0x111, +90
jne r0, 0x9d, +5
ldxw r0, [r6+20]
jne r0, 0x0, +83
ldxw r0, [r6+16]
jeq r0, 0x4, +85
ja +80
jne r0, 0xc9, +5
ldxw r0, [r6+20]
jne r0, 0x0, +77
ldxw r0, [r6+16]
jeq r0, 0x0, +79
ja +74
jne r0, 0x120, +6
ldxw r0, [r6+44]
jne r0, 0x0, +71
ldxw r0, [r6+40]
and32 r0, 0xfff7f7ff
jeq r0, 0x0, +72
ja +67
jne r0, 0xe, +5
ldxw r0, [r6+20]
jne r0, 0x0, +64
ldxw r0, [r6+16]
jeq r0, 0x2, +66
ja +68
jne r0, 0x49, +6
ldxw r0, [r6+28]
jne r0, 0x0, +58
ldxw r0, [r6+24]
jeq r0, 0x8, +60
jeq r0, 0x6, +59
ja +54
jne r0, 0x7, +9
ldxw r0, [r6+28]
jne r0, 0x0, +51
ldxw r0, [r6+24]
jne r0, 0x1, +49
ldxw r0, [r6+36]
jne r0, 0x0, +47
ldxw r0, [r6+32]
jeq r0, 0xa, +49
ja +44
jne r0, 0x19, +12
ldxw r0, [r6+20]
jne r0, 0x7fd1, +5
ldxw r0, [r6+16]
mov32 r2, 0xa8027000
jne r0, r2, +2
mov32 r0, 0x0
exit
ldxw r0, [r6+44]
jne r0, 0x0, +34
ldxw r0, [r6+40]
jeq r0, 0x1, +36
ja +31
jne r0, 0x35, +9
ldxw r0, [r6+20]
jne r0, 0x0, +28
ldxw r0, [r6+16]
jne r0, 0x1, +26
ldxw r0, [r6+28]
jne r0, 0x0, +24
ldxw r0, [r6+24]
jeq r0, 0x80001, +26
ja +21
jne r0, 0x37, +9
ldxw r0, [r6+28]
jne r0, 0x0, +18
ldxw r0, [r6+24]
jne r0, 0x1, +16
ldxw r0, [r6+36]
jne r0, 0x0, +14
ldxw r0, [r6+32]
jeq r0, 0x4, +16
ja +11
jne r0, 0xca, +7
ldxw r0, [r6+28]
jne r0, 0x0, +8
ldxw r0, [r6+24]
jeq r0, 0x80, +10
jeq r0, 0x81, +9
jeq r0, 0x189, +8
ja +3
jne r0, 0xe9, +11
ldxw r0, [r6+28]
jeq r0, 0x0, +2
mov32 r0, 0x30000
exit
ldxw r0, [r6+24]
jne r0, 0x2, +2
mov32 r0, 0x7fff0000
exit
jeq r0, 0x3, +339
jeq r0, 0x1, +338
ja +335
jne r0, 0x101, +16
ldxw r0, [r6+20]
mov32 r2, 0xffffffff
jne r0, r2, +331
ldxw r0, [r6+16]
mov32 r2, 0xffffff9c
jne r0, r2, +328
ldxw r0, [r6+28]
jne r0, 0x7fd1, +326
ldxw r0, [r6+24]
mov32 r2, 0xa81274f2
jne r0, r2, +323
ldxw r0, [r6+36]
jne r0, 0x0, +321
ldxw r0, [r6+32]
jeq r0, 0x90800, +321
ja +318
jne r0, 0x36, +14
ldxw r0, [r6+28]
jne r0, 0x0, +315
ldxw r0, [r6+24]
jne r0, 0x0, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x13, +311
jne r0, 0x1, +308
ldxw r0, [r6+36]
jne r0, 0x0, +306
ldxw r0, [r6+32]
jeq r0, 0x2, +306
ja +303
jne r0, 0xd, +12
ldxw r0, [r6+20]
jne r0, 0x0, +300
ldxw r0, [r6+16]
jeq r0, 0x19, +300
jeq r0, 0x11, +299
jeq r0, 0x1, +298
jeq r0, 0xc, +297
jeq r0, 0xa, +296
jeq r0, 0xd, +295
jeq r0, 0xf, +294
jeq r0, 0x2, +293
ja +290
jne r0, 0xa, +31
ldxw r0, [r6+20]
jlt r0, 0x7fd1, +21
ldxw r0, [r6+16]
mov32 r2, 0xa81279d5
jle r0, r2, +8
ldxw r0, [r6+28]
jlt r0, 0x0, +6
ldxw r0, [r6+24]
jgt r0, 0x100000, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x3, +278
mov32 r2, 0xa8027000
jge r0, r2, +8
ldxw r0, [r6+28]
jlt r0, 0x0, +6
ldxw r0, [r6+24]
jgt r0, 0x100000, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x3, +268
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x0, +264
jne r0, 0x0, +261
ldxw r0, [r6+32]
jeq r0, 0x1, +261
ja +258
jne r0, 0x29, +49
ldxw r0, [r6+20]
jne r0, 0x0, +255
ldxw r0, [r6+16]
jne r0, 0x10, +8
ldxw r0, [r6+28]
jne r0, 0x0, +6
ldxw r0, [r6+24]
jne r0, 0x3, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x0, +247
jne r0, 0x2, +14
ldxw r0, [r6+28]
jne r0, 0x0, +12
ldxw r0, [r6+24]
and32 r0, 0xfff7f7ff
jne r0, 0x2, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x0, +237
jne r0, 0x1, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x6, +232
jne r0, 0xa, +14
ldxw r0, [r6+28]
jne r0, 0x0, +12
ldxw r0, [r6+24]
and32 r0, 0xfff7f7ff
jne r0, 0x2, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x0, +222
jne r0, 0x1, +4
ldxw r0, [r6+36]
jne r0, 0x0, +2
ldxw r0, [r6+32]
jeq r0, 0x6, +217
jne r0, 0x1, +214
ldxw r0, [r6+28]
jne r0, 0x0, +212
ldxw r0, [r6+24]
and32 r0, 0xfff7f7ff
jeq r0, 0x1, +211
ja +208
jne r0, 0x2, +84
ldxw r0, [r6+20]
jne r0, 0x7fd1, +75
ldxw r0, [r6+16]
mov32 r2, 0xa81273fd
jeq r0, r2, +204
mov32 r2, 0xa81273de
jeq r0, r2, +202
mov32 r2, 0xa81273bf
jeq r0, r2, +200
mov32 r2, 0xa812739c
jeq r0, r2, +198
mov32 r2, 0xa8127379
jeq r0, r2, +196
mov32 r2, 0xa8127352
jeq r0, r2, +194
mov32 r2, 0xa8127325
jeq r0, r2, +192
mov32 r2, 0xa81272f4
jeq r0, r2, +190
mov32 r2, 0xa81272cb
jeq r0, r2, +188
mov32 r2, 0xa812729e
jeq r0, r2, +186
mov32 r2, 0xa812725a
jeq r0, r2, +184
mov32 r2, 0xa812727a
jeq r0, r2, +182
mov32 r2, 0xa8127236
jeq r0, r2, +180
mov32 r2, 0xa812720e
jeq r0, r2, +178
mov32 r2, 0xa81271c8
jeq r0, r2, +176
mov32 r2, 0xa81271a3
jeq r0, r2, +174
mov32 r2, 0xa81271e9
jeq r0, r2, +172
mov32 r2, 0xa812717a
jeq r0, r2, +170
mov32 r2, 0xa81274c9
jeq r0, r2, +168
mov32 r2, 0xa8127138
jeq r0, r2, +166
mov32 r2, 0xa8127000
jeq r0, r2, +164
mov32 r2, 0xa8127157
jeq r0, r2, +162
mov32 r2, 0xa8127111
jeq r0, r2, +160
mov32 r2, 0xa81274a2
jeq r0, r2, +158
mov32 r2, 0xa81270f9
jeq r0, r2, +156
mov32 r2, 0xa81270b7
jeq r0, r2, +154
mov32 r2, 0xa81270da
jeq r0, r2, +152
mov32 r2, 0xa8127099
jeq r0, r2, +150
mov32 r2, 0xa8127077
jeq r0, r2, +148
mov32 r2, 0xa8127495
jeq r0, r2, +146
mov32 r2, 0xa8127488
jeq r0, r2, +144
mov32 r2, 0xa812747c
jeq r0, r2, +142
mov32 r2, 0xa8127471
jeq r0, r2, +140
mov32 r2, 0xa8127463
jeq r0, r2, +138
mov32 r2, 0xa8127452
jeq r0, r2, +136
mov32 r2, 0xa812743a
jeq r0, r2, +134
mov32 r2, 0xa8127418
jeq r0, r2, +132
ldxw r0, [r6+28]
jne r0, 0x0, +128
ldxw r0, [r6+24]
and32 r0, 0xfff7f6ff
jne r0, 0x0, +125
mov32 r0, 0x5000d
exit
jne r0, 0x52, +122
ldxw r0, [r6+20]
jne r0, 0x7fd1, +120
ldxw r0, [r6+16]
mov32 r2, 0xa81273de
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa81273fd
jeq r0, r2, +114
mov32 r2, 0xa812739c
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa81273bf
jeq r0, r2, +107
mov32 r2, 0xa8127352
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127379
jeq r0, r2, +100
mov32 r2, 0xa81272f4
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127325
jeq r0, r2, +93
mov32 r2, 0xa812729e
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa81272cb
jeq r0, r2, +86
mov32 r2, 0xa812727a
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa812725a
jeq r0, r2, +79
mov32 r2, 0xa8127236
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa812725a
jeq r0, r2, +72
mov32 r2, 0xa812720e
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127236
jeq r0, r2, +65
mov32 r2, 0xa81271e9
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa81271c8
jeq r0, r2, +58
mov32 r2, 0xa81271a3
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa81271c8
jeq r0, r2, +51
mov32 r2, 0xa812717a
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa81271a3
jeq r0, r2, +44
mov32 r2, 0xa8127157
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127138
jeq r0, r2, +37
mov32 r2, 0xa8127000
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127138
jeq r0, r2, +30
mov32 r2, 0xa8127111
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127000
jeq r0, r2, +23
mov32 r2, 0xa81270f9
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127042
jeq r0, r2, +16
mov32 r2, 0xa81270b7
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa81270da
jeq r0, r2, +9
mov32 r2, 0xa8127077
jne r0, r2, +5
ldxw r0, [r6+28]
jne r0, 0x7fd1, +3
ldxw r0, [r6+24]
mov32 r2, 0xa8127099
jeq r0, r2, +2
mov32 r0, 0x30000
exit
mov32 r0, 0x7fff0000
exit
mov32 r0, 0x0
exit
