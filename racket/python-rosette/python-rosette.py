#!/usr/bin/env python3

import dis
import fileinput
import importlib.util
import inspect
import sys


def list_to_str(lst):
    return '#(' + ' '.join([str(x) for x in lst]) + ')'

class RosetteEmitter:

    def header(self):
        self.write("#lang rosette\n\n")
        self.write("; DO NOT MODIFY.\n;\n"
                   "; This file was automatically generated.\n\n"
                   "(provide (all-defined-out))\n")

    def footer(self):
        pass

    def write(self, s):
        sys.stdout.write(s)

    def emit_function(self, func):
        code = func.__code__
        self.write(f"\n(define {func.__name__} #hash(")
        # co_consts
        self.write(f"\n  (co_consts . {list_to_str(code.co_consts)})")
        # co_varnames
        self.write(f"\n  (co_varnames . {list_to_str(code.co_varnames)})")
        # co_names
        self.write(f"\n  (co_names . {list_to_str(code.co_names)})")
        # co_nlocals
        self.write(f"\n  (co_nlocals . {code.co_nlocals})")
        for instr in dis.Bytecode(func):
            arg = f" {instr.arg}" if instr.arg is not None else ''
            self.write(f"\n  ({instr.offset} . ({instr.opname}{arg}))")
        self.write("))\n")


def main():
    code = ''.join(fileinput.input())
    spec = importlib.util.spec_from_loader("", loader=None)
    module = importlib.util.module_from_spec(spec)
    exec(code, module.__dict__)

    emitter = RosetteEmitter()
    emitter.header()
    # ignore Z3 functions
    for name, f in inspect.getmembers(module, lambda x: inspect.isfunction(x) and inspect.getmodule(x) is None):
        emitter.emit_function(f)
    emitter.footer()


if __name__ == "__main__":
    main()
