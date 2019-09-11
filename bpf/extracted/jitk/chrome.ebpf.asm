xor32 r0, r0
xor32 r7, r7
mov r6, r1
ldxw r0, [r6+4]
mov32 r2, 0xc000003e
jne r0, r2, +139
ldxw r0, [r6]
jset r0, 0x40000000, +1
ja +2
mov32 r0, 0x30007
exit
jlt r0, 0x77, +58
jlt r0, 0xd9, +23
jlt r0, 0x10e, +5
jlt r0, 0x11e, +46
jlt r0, 0x123, +42
jlt r0, 0x12e, +39
jge r0, 0x12f, +316
ja +346
jlt r0, 0xe5, +9
jlt r0, 0xec, +5
jlt r0, 0xf8, +2
jge r0, 0x101, +342
ja +310
jge r0, 0xf7, +320
ja +308
jlt r0, 0xe7, +307
jge r0, 0xeb, +337
ja +316
jlt r0, 0xdc, +3
jlt r0, 0xdd, +334
jge r0, 0xe4, +313
ja +301
jlt r0, 0xda, +331
jge r0, 0xdb, +310
ja +298
jlt r0, 0x95, +91
jlt r0, 0xc8, +9
jlt r0, 0xcd, +5
jlt r0, 0xd5, +2
jge r0, 0xd6, +293
ja +303
jge r0, 0xd4, +322
ja +290
jlt r0, 0xcb, +300
jge r0, 0xcc, +299
ja +287
jlt r0, 0x9e, +3
jlt r0, 0xba, +285
jge r0, 0xbb, +284
ja +294
jlt r0, 0x97, +293
jlt r0, 0x9d, +281
ldxw r0, [r6+20]
jeq r0, 0x0, +51
ja +45
jge r0, 0x126, +277
ja +287
jlt r0, 0x120, +275
jge r0, 0x121, +274
ja +304
jlt r0, 0x113, +5
jlt r0, 0x119, +2
jge r0, 0x11d, +301
ja +269
jge r0, 0x118, +299
ja +267
jlt r0, 0x110, +277
jge r0, 0x111, +276
ja +264
jlt r0, 0x38, +76
jlt r0, 0x63, +17
jlt r0, 0x6b, +9
jlt r0, 0x6f, +5
jlt r0, 0x74, +2
jge r0, 0x76, +269
ja +257
jge r0, 0x73, +267
ja +255
jlt r0, 0x6d, +265
jge r0, 0x6e, +264
ja +252
jlt r0, 0x67, +3
jlt r0, 0x68, +250
jge r0, 0x69, +249
ja +259
jlt r0, 0x65, +258
jge r0, 0x66, +257
ja +245
jlt r0, 0x44, +238
jlt r0, 0x4a, +5
jlt r0, 0x60, +2
jge r0, 0x62, +241
ja +251
jge r0, 0x4c, +270
ja +249
jlt r0, 0x48, +268
jge r0, 0x49, +236
ldxw r0, [r6+28]
jeq r0, 0x0, +146
ja +140
mov32 r2, 0xffffffff
jne r0, r2, +266
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jlt r0, r2, +263
ldxw r0, [r6+16]
jeq r0, 0xf, +237
ldxw r0, [r6+20]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +257
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jlt r0, r2, +254
ldxw r0, [r6+16]
jeq r0, 0x4, +228
ldxw r0, [r6+20]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +248
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jlt r0, r2, +245
ldxw r0, [r6+16]
jeq r0, 0x3, +219
mov32 r0, 0x30005
exit
jlt r0, 0x87, +9
jlt r0, 0x8c, +5
jlt r0, 0x8f, +2
jge r0, 0x94, +202
ja +212
jge r0, 0x8e, +200
ja +210
jlt r0, 0x88, +198
jge r0, 0x8a, +197
ja +227
jlt r0, 0x7c, +3
jlt r0, 0x7e, +205
jge r0, 0x84, +224
ja +192
jlt r0, 0x78, +191
jge r0, 0x79, +190
ja +200
mov32 r0, 0x30002
exit
jlt r0, 0x16, +5
jlt r0, 0x28, +76
jlt r0, 0x31, +72
jlt r0, 0x35, +69
jge r0, 0x36, +182
ja +57
jlt r0, 0x7, +4
jlt r0, 0xb, +31
jlt r0, 0x11, +9
jge r0, 0x15, +208
ja +187
jlt r0, 0x4, +3
jlt r0, 0x5, +205
jge r0, 0x6, +204
ja +183
jlt r0, 0x2, +182
jge r0, 0x3, +181
ja +200
jlt r0, 0x10, +179
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +199
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +196
ldxw r0, [r6+24]
jeq r0, 0x5401, +170
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +190
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +187
ldxw r0, [r6+24]
jeq r0, 0x541b, +161
mov32 r0, 0x30003
exit
jlt r0, 0x9, +158
jlt r0, 0xa, +11
ldxw r0, [r6+36]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +177
ldxw r0, [r6+32]
mov32 r2, 0x80000000
jlt r0, r2, +174
ldxw r0, [r6+32]
mov32 r2, 0xfffffff8
jset r0, r2, +136
ja +146
ldxw r0, [r6+44]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +166
ldxw r0, [r6+40]
mov32 r2, 0x80000000
jlt r0, r2, +163
ldxw r0, [r6+40]
mov32 r2, 0xfffdb7cc
jset r0, r2, +125
ja +135
ldxw r0, [r6+20]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +155
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jlt r0, r2, +152
ldxw r0, [r6+16]
jeq r0, 0x1, +126
ja +114
jge r0, 0x33, +113
ja +143
jlt r0, 0x29, +111
jge r0, 0x2c, +121
ja +140
jlt r0, 0x1d, +3
jlt r0, 0x24, +118
jge r0, 0x27, +117
ja +105
jlt r0, 0x1a, +115
jlt r0, 0x1c, +103
ldxw r0, [r6+36]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +134
ldxw r0, [r6+32]
mov32 r2, 0x80000000
jlt r0, r2, +131
ldxw r0, [r6+32]
jeq r0, 0x4, +105
ja +124
mov32 r2, 0xffffffff
jne r0, r2, +126
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +123
ldxw r0, [r6+24]
jeq r0, 0x3, +97
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +117
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +114
ldxw r0, [r6+24]
jne r0, 0x4, +7
ldxw r0, [r6+36]
mov32 r2, 0xffffffff
jset r0, r2, +74
ldxw r0, [r6+32]
mov32 r2, 0xffe363fc
jset r0, r2, +71
ja +81
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +101
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +98
ldxw r0, [r6+24]
jeq r0, 0x1, +72
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +92
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +89
ldxw r0, [r6+24]
jeq r0, 0x2, +63
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +83
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +80
ldxw r0, [r6+24]
jeq r0, 0x0, +54
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +74
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +71
ldxw r0, [r6+24]
jeq r0, 0x6, +45
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +65
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +62
ldxw r0, [r6+24]
jeq r0, 0x7, +36
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +56
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +53
ldxw r0, [r6+24]
jeq r0, 0x5, +27
ldxw r0, [r6+28]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +47
ldxw r0, [r6+24]
mov32 r2, 0x80000000
jlt r0, r2, +44
ldxw r0, [r6+24]
jeq r0, 0x406, +18
ja +6
jlt r0, 0x3c, +3
jlt r0, 0x40, +15
jge r0, 0x43, +14
ja +33
jlt r0, 0x39, +3
jge r0, 0x3b, +31
mov32 r0, 0x30001
exit
ldxw r0, [r6+20]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +29
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jlt r0, r2, +26
ldxw r0, [r6+16]
jne r0, 0x3d0f00, +2
mov32 r0, 0x7fff0000
exit
ldxw r0, [r6+20]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +18
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jlt r0, r2, +15
ldxw r0, [r6+16]
jeq r0, 0x100011, +9
ldxw r0, [r6+20]
jeq r0, 0x0, +5
mov32 r2, 0xffffffff
jne r0, r2, +9
ldxw r0, [r6+16]
mov32 r2, 0x80000000
jlt r0, r2, +6
ldxw r0, [r6+16]
jne r0, 0x1200011, +2
mov32 r0, 0x50001
exit
mov32 r0, 0x30004
exit
mov32 r0, 0x30006
exit
