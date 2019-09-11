#!/usr/bin/env bash

echo
echo "Komodo Refinement -O0"
make -s clean
time bash -c "make -s 'CONFIG_VERIFICATION=1' 'OLEVEL=0' verify-komono-riscv  >/dev/null"

echo
echo "Komodo Refinement -O1"
make -s clean
time bash -c "make -s 'CONFIG_VERIFICATION=1' 'OLEVEL=1' verify-komono-riscv  >/dev/null"


echo
echo "Komodo Refinement -O2"
make -s clean
time bash -c "make -s 'CONFIG_VERIFICATION=1' 'OLEVEL=2' verify-komono-riscv  >/dev/null"

echo
echo "Komodo Safety Proof"
make -s clean
time bash -c """
make -s CONFIG_VERIFICATION=1 verify-komono-invariants >/dev/null;
make -s CONFIG_VERIFICATION=1 verify-komono-nickel-ni >/dev/null;
"""

echo
echo "CertiKOS Refinement -O0"
make -s clean
time bash -c "make -s 'CONFIG_VERIFICATION=1' 'OLEVEL=0' verify-isomon-riscv  >/dev/null"

echo
echo "CertiKOS Refinement -O1"
make -s clean
time bash -c "make -s 'CONFIG_VERIFICATION=1' 'OLEVEL=1' verify-isomon-riscv  >/dev/null"

echo
echo "CertiKOS Refinement -O2"
make -s clean
time bash -c "make -s 'CONFIG_VERIFICATION=1' 'OLEVEL=2' verify-isomon-riscv  >/dev/null"

echo
echo "CertiKOS Safety Proof"
make -s clean
time bash -c """
make -s CONFIG_VERIFICATION=1 verify-isomon-spec >/dev/null;
make -s CONFIG_VERIFICATION=1 verify-isomon-nickel-ni >/dev/null;
"""