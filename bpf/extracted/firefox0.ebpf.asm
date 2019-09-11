xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxw r0, [r6+4]
mov32 r2, 0xc000003e
jne r0, r2, +3
ldxw r0, [r6]
jset r0, 0x40000000, +1
ja +1
ja +549
jlt r0, 0x79, +98
jlt r0, 0xea, +49
jlt r0, 0x112, +24
jlt r0, 0x126, +12
jlt r0, 0x12f, +6
jlt r0, 0x134, +3
jlt r0, 0x13e, +203
jge r0, 0x140, +202
ja +187
jge r0, 0x133, +186
ja +199
jlt r0, 0x12a, +2
jge r0, 0x12e, +185
ja +196
jge r0, 0x129, +217
ja +194
jlt r0, 0x11e, +5
jlt r0, 0x124, +2
jge r0, 0x125, +177
ja +190
jge r0, 0x122, +175
ja +188
jlt r0, 0x11a, +2
jge r0, 0x11d, +172
ja +185
jge r0, 0x119, +170
ja +183
jlt r0, 0x105, +12
jlt r0, 0x10c, +6
jlt r0, 0x10e, +3
jlt r0, 0x110, +165
jge r0, 0x111, +164
ja +177
jge r0, 0x10d, +180
ja +175
jlt r0, 0x107, +2
jge r0, 0x10b, +179
ja +172
jge r0, 0x106, +179
ja +170
jlt r0, 0x101, +5
jlt r0, 0x103, +2
jge r0, 0x104, +137
ja +176
jge r0, 0x102, +165
ja +184
jlt r0, 0xef, +2
jge r0, 0xf0, +162
ja +147
jge r0, 0xeb, +160
ja +181
jlt r0, 0xc8, +24
jlt r0, 0xda, +12
jlt r0, 0xde, +6
jlt r0, 0xe5, +3
jlt r0, 0xe6, +140
jge r0, 0xe7, +139
ja +152
jge r0, 0xe4, +184
ja +150
jlt r0, 0xdc, +2
jge r0, 0xdd, +134
ja +147
jge r0, 0xdb, +132
ja +145
jlt r0, 0xce, +5
jlt r0, 0xd6, +2
jge r0, 0xd9, +128
ja +141
jge r0, 0xd5, +126
ja +139
jlt r0, 0xcb, +2
jge r0, 0xcc, +123
ja +106
jge r0, 0xc9, +121
ja +228
jlt r0, 0x8c, +11
jlt r0, 0x9d, +5
jlt r0, 0xba, +2
jge r0, 0xbc, +130
ja +115
jge r0, 0x9e, +128
ja +223
jlt r0, 0x95, +2
jge r0, 0x97, +125
ja +110
jge r0, 0x94, +123
ja +108
jlt r0, 0x86, +5
jlt r0, 0x8a, +2
jge r0, 0x8b, +119
ja +104
jge r0, 0x89, +254
ja +116
jlt r0, 0x84, +2
jge r0, 0x85, +253
ja +83
jge r0, 0x83, +98
ja +111
jlt r0, 0x3e, +49
jlt r0, 0x5a, +24
jlt r0, 0x68, +12
jlt r0, 0x6e, +6
jlt r0, 0x76, +3
jlt r0, 0x77, +91
jge r0, 0x78, +90
ja +103
jge r0, 0x6f, +102
ja +252
jlt r0, 0x6b, +2
jge r0, 0x6d, +99
ja +84
jge r0, 0x69, +97
ja +82
jlt r0, 0x60, +5
jlt r0, 0x66, +2
jge r0, 0x67, +93
ja +78
jge r0, 0x65, +91
ja +76
jlt r0, 0x5c, +2
jge r0, 0x5d, +88
ja +57
jge r0, 0x5b, +86
ja +238
jlt r0, 0x50, +12
jlt r0, 0x55, +6
jlt r0, 0x57, +3
jlt r0, 0x58, +240
jge r0, 0x59, +235
ja +236
jge r0, 0x56, +239
ja +77
jlt r0, 0x53, +2
jge r0, 0x54, +238
ja +239
jge r0, 0x52, +240
ja +72
jlt r0, 0x49, +5
jlt r0, 0x4d, +2
jge r0, 0x4f, +238
ja +54
jge r0, 0x4b, +67
ja +52
jlt r0, 0x40, +2
jge r0, 0x48, +235
ja +63
jge r0, 0x3f, +48
ja +61
jlt r0, 0x22, +24
jlt r0, 0x2c, +12
jlt r0, 0x36, +6
jlt r0, 0x39, +3
jlt r0, 0x3c, +56
jge r0, 0x3d, +341
ja +40
jge r0, 0x38, +341
ja +38
jlt r0, 0x33, +2
jge r0, 0x35, +350
ja +35
jge r0, 0x31, +48
ja +33
jlt r0, 0x28, +5
jlt r0, 0x2a, +2
jge r0, 0x2b, +44
ja +389
jlt r0, 0x29, +42
ja +389
jlt r0, 0x24, +2
jge r0, 0x27, +25
ja +38
jge r0, 0x23, +23
ja +36
jlt r0, 0x11, +11
jlt r0, 0x1c, +5
jlt r0, 0x1e, +2
jge r0, 0x20, +18
ja +31
jlt r0, 0x1d, +16
ja +379
jlt r0, 0x16, +2
jlt r0, 0x1b, +13
ja +378
jlt r0, 0x15, +11
ja +381
jlt r0, 0x5, +5
jlt r0, 0x7, +2
jlt r0, 0x10, +7
ja +379
jlt r0, 0x6, +5
ja +395
jlt r0, 0x3, +2
jlt r0, 0x4, +2
ja +394
jge r0, 0x2, +1
ja +396
ja +393
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +347
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +343
ldxw r0, [r6+16]
jne r0, 0x0, +2
ldxw r0, [r6+36]
jeq r0, 0x0, +1
ja +384
ldxw r0, [r6+32]
jeq r0, 0x0, +380
ja +381
mov32 r0, 0x30017
exit
mov32 r0, 0x30016
exit
mov32 r0, 0x30015
exit
ldxw r0, [r6+36]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +325
ldxw r0, [r6+32]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +321
ldxw r0, [r6+32]
ja +128
mov32 r0, 0x30014
exit
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +313
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +309
ldxw r0, [r6+16]
jeq r0, 0x309c, +351
ja +352
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +302
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +298
ldxw r0, [r6+16]
jeq r0, 0x1, +340
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +292
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +288
ldxw r0, [r6+16]
jeq r0, 0x6, +330
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +282
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +278
ldxw r0, [r6+16]
jeq r0, 0x2, +320
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +272
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +268
ldxw r0, [r6+16]
jeq r0, 0x0, +310
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +262
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +258
ldxw r0, [r6+16]
jeq r0, 0x5, +300
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +252
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +248
ldxw r0, [r6+16]
jeq r0, 0x3, +290
ja +291
mov32 r0, 0x30013
exit
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +239
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +235
ldxw r0, [r6+16]
jeq r0, 0x15, +277
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +229
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +225
ldxw r0, [r6+16]
jeq r0, 0xf, +267
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +219
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +215
ldxw r0, [r6+16]
jeq r0, 0x4, +257
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +209
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +205
ldxw r0, [r6+16]
jeq r0, 0x59616d61, +247
ja +248
mov32 r0, 0x30012
exit
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +196
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +192
ldxw r0, [r6+24]
and32 r0, 0xf000
jeq r0, 0x2000, +200
ja +234
mov32 r0, 0x30011
exit
mov32 r0, 0x30010
exit
mov32 r0, 0x3000f
exit
mov32 r0, 0x3000e
exit
mov32 r0, 0x3000d
exit
mov32 r0, 0x3000c
exit
mov32 r0, 0x3000b
exit
mov32 r0, 0x3000a
exit
mov32 r0, 0x30009
exit
mov32 r0, 0x50002
exit
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +164
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +160
ldxw r0, [r6+24]
jeq r0, 0x1, +202
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +154
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +150
ldxw r0, [r6+24]
jeq r0, 0x2, +83
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +144
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +140
ldxw r0, [r6+24]
jeq r0, 0x3, +182
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +134
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +130
ldxw r0, [r6+24]
jeq r0, 0x4, +51
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +124
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +120
ldxw r0, [r6+24]
jeq r0, 0x406, +162
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +114
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +110
ldxw r0, [r6+24]
jeq r0, 0x6, +152
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +104
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +100
ldxw r0, [r6+24]
jeq r0, 0x6, +142
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +94
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +90
ldxw r0, [r6+24]
jeq r0, 0x7, +132
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +84
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +80
ldxw r0, [r6+24]
jeq r0, 0x7, +122
ja +123
ldxw r0, [r6+36]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +73
ldxw r0, [r6+32]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +69
ldxw r0, [r6+32]
mov32 r2, 0xfff773fc
jset r0, r2, +112
ja +109
ldxw r0, [r6+36]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +61
ldxw r0, [r6+32]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +57
ldxw r0, [r6+32]
mov32 r2, 0xfffffffe
jset r0, r2, +100
ja +97
mov32 r0, 0x5000a
exit
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +47
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +43
ldxw r0, [r6+16]
and32 r0, 0xffbfffff
jeq r0, 0x3d0f00, +84
ja +50
ldxw r0, [r6+20]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +35
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +31
ldxw r0, [r6+16]
jne r0, 0x1, +75
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +25
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +21
ldxw r0, [r6+24]
and32 r0, 0xfff7f7ff
jeq r0, 0x1, +62
ldxw r0, [r6+28]
jeq r0, 0x0, +6
mov32 r2, 0xffffffff
jne r0, r2, +14
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +1
ja +10
ldxw r0, [r6+24]
and32 r0, 0xfff7f7ff
jeq r0, 0x5, +51
ldxw r0, [r6+28]
jeq r0, 0x0, +7
mov32 r2, 0xffffffff
jne r0, r2, +3
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jset r0, r2, +2
mov32 r0, 0x0
exit
ldxw r0, [r6+24]
and32 r0, 0xfff7f7ff
jne r0, 0x2, +41
mov32 r0, 0x30008
exit
mov32 r0, 0x30007
exit
mov32 r0, 0x30006
exit
mov32 r0, 0x50001
exit
ldxw r0, [r6+28]
jne r0, 0x0, +31
ldxw r0, [r6+24]
jeq r0, 0x1000, +27
ja +28
mov32 r0, 0x30005
exit
ldxw r0, [r6+28]
jne r0, 0x0, +2
ldxw r0, [r6+24]
jeq r0, 0x5451, +20
ldxw r0, [r6+28]
jne r0, 0x0, +2
ldxw r0, [r6+24]
jeq r0, 0x5421, +16
ldxw r0, [r6+28]
jne r0, 0x0, +2
ldxw r0, [r6+24]
jeq r0, 0x5401, +4
ldxw r0, [r6+24]
and32 r0, 0xff00
jeq r0, 0x5400, +11
ja +8
mov32 r0, 0x50019
exit
mov32 r0, 0x30004
exit
mov32 r0, 0x30003
exit
mov32 r0, 0x30002
exit
mov32 r0, 0x7fff0000
exit
mov32 r0, 0x30001
exit
