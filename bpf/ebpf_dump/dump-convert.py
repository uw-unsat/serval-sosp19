#!/usr/bin/env python3

# Convert Linux's linx hex dump to raw binary file
#
# Example input format:
#
# [   23.060918] JIT code: 00000000: 55 48 89 e5 48 81 ec 28 02 00 00 48 89 9d d8 fd
# [   23.062600] JIT code: 00000010: ff ff 4c 89 ad e0 fd ff ff 4c 89 b5 e8 fd ff ff
# [   23.064259] JIT code: 00000020: 4c 89 bd f0 fd ff ff 31 c0 48 89 85 f8 fd ff ff
# [   23.065909] JIT code: 00000030: b8 37 13 00 00 48 c7 c7 be ba fe ca 48 8b 9d d8
# [   23.067549] JIT code: 00000040: fd ff ff 4c 8b ad e0 fd ff ff 4c 8b b5 e8 fd ff
# [   23.069210] JIT code: 00000050: ff 4c 8b bd f0 fd ff ff c9 c3
#

import sys

if len(sys.argv) < 3:
	print("Usage: {} <in> <out>".format(sys.argv[0]))
	exit(1)

result = b''

with open(sys.argv[1]) as f:
    for line in f:
        if len(line) > 0:
            hexes = line.split(':')[2].strip().split(' ')
            for byte in hexes:
                result += bytes([int(byte, 16)])

with open(sys.argv[2], 'wb') as f:
    f.write(result)
