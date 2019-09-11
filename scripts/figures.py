#!/usr/bin/env python3

import timeit
import time
import subprocess
import glob
import os

NULLF = open(os.devnull, 'w')


def clean():
    r = subprocess.call(["make", "-s", "clean"])
    assert r == 0

class Verifier:

    SYSTEMS = ['komodo', 'certikos']
    OLEVELS = [0, 1, 2]

    def time(self):
        clean()
        start = time.time()
        self.run()
        end = time.time()
        return end - start


class RefinementVerifier(Verifier):
    def __init__(self, *, olevel, system):
        assert olevel in self.OLEVELS
        assert system in self.SYSTEMS
        self.olevel = olevel
        self.system = system

    def run(self):
        r = subprocess.call([
            "make",
            "-s",
            "CONFIG_VERIFICATION=1",
            f"OLEVEL={self.olevel}",
            f"verify-{self.system}-riscv",
        ], stdout=NULLF)
        assert r == 0


class SafetyVerifier(Verifier):
    def __init__(self, *, system):
        assert system in self.SYSTEMS
        self.system = system

    def run(self):
        r = subprocess.call([
            "make", "-s", "CONFIG_VERIFICATION=1",
            f"verify-{self.system}-invariants"], stdout=NULLF)
        assert r == 0
        r = subprocess.call([
            "make", "-s", "CONFIG_VERIFICATION=1",
            f"verify-{self.system}-nickel-ni"], stdout=NULLF)
        assert r == 0

def nr_lines(filename):
    t = 0
    with open(filename, 'r') as f:
        for l in f:
            if l != '\n':
                t += 1
    return t

def cloc(*files):
    total = 0
    for spec in files:
        for name in glob.glob(spec):
            total += nr_lines(name)
    return total

common_impl = [
    "include/asm/csr.h",
    "include/asm/pmp.h",
    "include/asm/entry.h",
    "include/asm/pgtable.h",
    "include/asm/ptrace.h",
    "include/asm/page.h",
    "include/io/compiler.h",
    "include/io/const.h",
    "include/io/sizes.h",
    "include/io/linkage.h",
    "include/io/build_bug.h",
    "include/asm/tlbflush.h",
    "include/asm/csr_bits/status.h",
    "include/asm/setup.h",
    "include/sys/errno.h",
    "include/sys/types.h",
    "include/sys/init.h",
    "include/sys/string.h",
    "include/sys/bug.h",
    "bios/entry.S",
    "bios/boot/head.S",
    "kernel/smp.c",
    "kernel/string.c",
    "kernel/traps.c",
]

print('===FIGURE 6===\n')

print(f'{"component":31}  {"lines of code":>15}')
print('-' * 50)

def component(name, *files):
    loc = cloc(*files)
    print(f'{name:31}  {loc:>14,}')
    return loc

serval_loc = 0
serval_loc += component("Serval framework",
  "serval/serval/lib/*.rkt",
  "serval/serval/spec/*.rkt",
  "serval/serval/spec/lang/*.rkt",
  "serval/serval/ubsan.rkt",
  "serval/serval/lang/*.rkt",
)

serval_loc += component("RISC-V verifier", "serval/serval/riscv/*.rkt")
serval_loc += component("x86-32 Verifier", "serval/serval/x32/*.rkt")
serval_loc += component("LLVM verifier", "serval/serval/llvm.rkt",
  "serval/serval/llvm/*.rkt")
serval_loc += component("BPF Verifier", "serval/serval/bpf.rkt")
print('-' * 50)
print(f'{"total":31}  {serval_loc:>14,}')


print('\n===FIGURE 8===')

print(f'  {"":25}  {"CertiKOS":>8}  {"Komono":>8}')
print('lines of code:')

k_impl = cloc('monitors/komodo/*.c', 'monitors/komodo/*.h', *common_impl)
c_impl = cloc('monitors/certikos/*.c', 'monitors/certikos/*.h', *common_impl)
print(f'  {"implementation":25}  {c_impl:8,}  {k_impl:8,}')

k_absri = cloc('monitors/komodo/verif/impl.rkt', 'monitors/komodo/verif/riscv.rkt')
c_absri = cloc('monitors/certikos/verif/impl.rkt', 'monitors/certikos/verif/riscv.rkt')
print(f'  {"abs. function + rep. inv":25}  {c_absri:8,}  {k_absri:8,}')

k_spec = cloc('monitors/komodo/verif/spec.rkt')
c_spec = cloc('monitors/certikos/verif/spec.rkt')
print(f'  {"state-machine spec":25}  {c_spec:8,}  {k_spec:8,}')

k_safety = cloc('monitors/komodo/verif/invariants.rkt',
    'monitors/komodo/verif/nickel-ni.rkt')
c_safety = cloc('monitors/certikos/verif/nickel-ni.rkt',
    'monitors/certikos/verif/invariants.rkt')
print(f'  {"safety":25}  {c_safety:8,}  {k_safety:8,}')

print('verification time (s):')
for o in Verifier.OLEVELS:
    certikos = RefinementVerifier(olevel=o, system='certikos').time()
    komodo = RefinementVerifier(olevel=o, system='komodo').time()
    print(f'  {f"refinement proof (-O{o})":25}  {certikos:8,.0f}  {komodo:8,.0f}')

c = SafetyVerifier(system='certikos').time()
k = SafetyVerifier(system='komodo').time()
print(f'  {"safety proof":25}  {c:8,.0f}  {k:8,.0f}')
