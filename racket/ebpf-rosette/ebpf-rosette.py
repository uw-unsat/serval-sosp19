#!/usr/bin/env python3

import fileinput
import shlex
import sys
import re
from collections import namedtuple


def label_name(s):
    return '$' + s


class RosetteEmitter:

    def header(self):
        self.write("#lang rosette\n\n")
        self.write("; DO NOT MODIFY.\n;\n"
                   "; This file was automatically generated.\n")
        self.write("(provide instructions)\n\n")
        self.write('\n(define instructions (make-immutable-hash (list\n')

    def footer(self):
        self.write(")))\n")

    def __init__(self):
        self.addr = 0

    def emit(self, line):

        elems = ' '.join(map(lambda x : x.strip(',').replace('0x', '#x'), line.split()))


        self.write("  (cons (bv #x{addr:016x} 64) '({elems}))\n".format(
            addr=self.addr,
            elems=elems,
        ))

        self.addr += 8

    def write(self, s):
        sys.stdout.write(s)


def main():
    emitter = RosetteEmitter()

    emitter.header()
    for line in fileinput.input():
        emitter.emit(line)

    emitter.footer()


if __name__ == "__main__":
    main()
