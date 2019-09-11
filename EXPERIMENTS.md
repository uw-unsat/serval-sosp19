# Serval SOSP'19 Artifact

This document describes the artifact for our SOSP'19
paper on Serval, a framework for building automated
verifiers for systems code. It explains how to run
the case studies and experiments described in the paper.

This guide is located in `EXPERIMENTS.md` in the artifact, and available
on the web at
<https://unsat.cs.washington.edu/projects/serval/sosp19-artifact.html>.

## Downloads

- [serval.tar.gz](https://unsat.cs.washington.edu/projects/serval/serval.tar.gz)
- [Docker image](https://hub.docker.com/r/unsat/serval-tools/tags) tag: artifact

## Artifact overview

We provide our artifact both as a tarball and as a Docker image.
**We highly recommend using the Docker image**; the rest
of this guide assumes that you are doing so.
The Docker image comes with known-working versions of all required tools
such as [Rosette], Z3, LLVM, and GCC.  This guide will show you
how to install Docker and use our Docker image below.

This artifact demonstrates how to replicate the key findings described
in the Serval paper.  Using this guide, you can play with the ToyRISC example,
run and verify both of our verified security monitors, run the BPF symbolic testing,
and replicate experimental data shown in the tables in the paper.
The total amount of time required to run all the commands is less than
1 hour, depending on your internet connection and hardware specifications.

These experiments were tested on and designed for a machine with
at least 4 CPU cores.  The tests will work a machine with fewer cores,
but with marked performance degradation. For reference, our results
were taken from a machine with an Intel(R) Core(TM) i7-7700K CPU @ 4.20GHz
CPU and 16.0 GiB of RAM. The tests also assume you have enough free disk
space for the Docker image as well as temporary files; anything over
16GB should suffice.

## Setting up docker

We provide a Docker image containing all of the tools necessary
to run the Serval experiments. In order to use the image,
you must have Docker installed. See <https://docs.docker.com/install/>
for details. If you are using macOS,
[Docker For Mac](https://docs.docker.com/docker-for-mac/install/)
is a good solution.

Once you have docker installed, the next step is to download
the Docker image, run it from the Serval directory, and
perform initial setup.

```bash
# Download image (~ 2 GB download)
$ docker pull unsat/serval-tools:artifact

# Run image
$ docker run -it --name serval unsat/serval-tools:artifact
```

This will drop you into a shell inside the container,
in the `/serval` directory containing source code
and experiments, which is an unpacked version of the tarball
download above.

The rest of this guide will assume that you run commands from
the `/serval` directory—things may not work as expected
otherwise.

We have installed `vim` into the container for convenience
to edit and view files;
you can also use Docker to copy files into and out of the container,
see <https://docs.docker.com/engine/reference/commandline/cp/>.

If you leave the container and wish to get back, you will
need to either delete the old container or reattach with
`docker start -ia serval`.

## Serval framework structure

The Serval framework and accompanied verifiers are located
under the `serval` directory. This directory is a Racket package
which is preinstalled into the Docker container. If you are not
using the container, or need to reinstall the package, you can do
so with `raco pkg install ./serval` from the `/serval` directory.
(Note that this is not necessary for completing this guide using the container.)

The Serval package directory layout is as follows:

- `serval/serval/lib`:
  Serval framework core libraries for building verifiers
- `serval/serval/spec`:
  Serval common specifications, e.g. refinement and noninterference
- `serval/serval/riscv`:
  RISC-V verifier
- `serval/serval/x32`:
  x86-32 verifier
- `serval/serval/llvm.rkt`:
  LLVM verifier
- `serval/serval/bpf.rkt`:
  BPF verifier


## ToyRISC example

A working version of the ToyRISC example from section 3
of the paper can be found in `racket/toyrisc.rkt`.  The file
is broken down into four parts—the ToyRISC interpreter,
the implementation and specification of the sign function,
code to verify state-machine refinement using Serval's libraries,
and code to check the noninterference-like safety property.

The sign function computes the sign of the value in register `a0`,
returning `-1`, `0`, or `1` in `a0` depending on the sign.  It uses
`a1` as a scratch register. You can run the ToyRISC example verification
with:

```bash
# Run ToyRISC verification (~ 1 sec.)
$ racket racket/toyrisc.rkt
```

If verification succeeds, both the test cases will pass,
with the following output:

```
ToyRISC tests
Running test "ToyRISC Refinement"
cpu time: 28 real time: 45 gc time: 0
Finished test "ToyRISC Refinement"
Running test "ToyRISC Safety"
cpu time: 3 real time: 13 gc time: 0
Finished test "ToyRISC Safety"
2 success(es) 0 failure(s) 0 error(s) 2 test(s) run
0
```

To test the state-machine refinement verification you can
introduce a bug into the implementation, for instance,
by replacing `(li 0 #f -1)` with `(li 0 #f -2)` on line 92.
This bug causes the implementation to return `-2` instead of
`-1` when `a0` is negative.

Re-running verification with `racket racket/toyrisc.rkt`, you
will observe that the refinement check has failed, printing:

```
Verification failed:
Initial implementation state: #(struct:cpu 0 #(-1 0))
Initial specification state: #(struct:state -1 0)
Final implementation state #(struct:cpu 0 #(-2 1))
Final specification state #(struct:state -1 1)
```

This constructed counterexample gives a concrete
initial state that demonstrates the bug; in particular,
it chooses `-1` as the initial value of `a0`.
The bug causes the implementation to return `-2` instead of `-1`
as described by the specification.

Similarly, you can experiment with making modifications
to the specification that violate the safety specification.

## Running and verifying security monitors

One of the main case studies in the paper is our experience
of porting and verifying the security monitors CertiKOS and Komodo
to be verified using Serval. This section describes run the ports
using QEMU, and how to run their verification using Serval.

**Running the implementations**

Our implementations of Komodo and CertiKOS are located
in `monitors/komodo` and `monitors/certikos`, respectively.
The ports can run in QEMU, the [Spike] RISC-V simulator, and on
physical HiFive Unleashed boards.

_Komodo_

Our port of the Komodo monitor comes with a test kernel
that exercises monitor behavior by creating and running enclave.
You can run it with:

```bash
# Run Komodo port (~ 2 sec.)
$ racket scripts/run.rkt --run komodo
```

The expected output for this test is:

```
komodo: driver init
komodo: 1024 pages available
komodo: running tests
[20 lines elided]
komodo: test complete: 0
```

_CertiKOS_

To test our CertiKOS port, we use a test program from the original
implementation that launches two processes that attempt to interfere.
You can run it with:

```bash
# Run CertiKOS port (~ 1 sec.)
$ racket scripts/run.rkt --run certikos
```

The expected output ends with:

```
Hacker: Wrote 'h' to index 33564672, quota is now 2.
Hacker: Wrote 'h' to index 50333696, quota is now 0.(page fault occurred, allocated 2 new page(s))
Hacker: I've been thwarted by CertiKOS, my memory usage was limited only by available quota,
which is completely independent from Alice's memory usage. I give up :(
```


Note that for either monitor you can choose to use the Spike simulator
instead of QEMU by adding `--spike` before `--run`;
this should not change the output of the test programs.


**Verification**

Specifications and verification infrastructure for the security
monitors is located in `monitors/komodo/verif` and `monitors/certikos/verif`.
The files in these directories contain the state-machine specifications,
noninterference policies, and infrastructure that leverages the Serval
framework to verify the monitors' implementations. You can run the verification
as follows:

```bash
# Run Komodo verification (~ 7 min.)
$ racket scripts/run.rkt --verify komodo

# Run CertiKOS verification (~ 3 min.)
$ racket scripts/run.rkt --verify certikos
```

The end of the expected output for Komodo is:

```
  56 monitors/komodo/verif/invariants.rkt
  37 monitors/komodo/verif/nickel-ni.rkt
  33 monitors/komodo/verif/riscv.rkt
  12 monitors/komodo/verif/llvm.rkt
   1 monitors/komodo/verif/basic.rkt
139 tests passed
```

and for CertiKOS is:

```
  36 monitors/certikos/verif/nickel-ni.rkt
  12 monitors/certikos/verif/ni.rkt
   6 monitors/certikos/verif/riscv.rkt
   6 monitors/certikos/verif/invariants.rkt
   4 monitors/certikos/verif/llvm.rkt
   1 monitors/certikos/verif/basic.rkt
65 tests passed
```

Verification for each of the monitors is broken down into four
parts as follows, under `monitors/certikos/verif` and `monitors/komodo/verif`.

- `riscv.rkt`:
  RISC-V state-machine refinement and helper functions
  for using Serval.
- `llvm.rkt`:
  LLVM state-machine refinement, which is used to help
  debug the RISC-V refinement.
- `invariants.rkt`:
  State-machine specification invariants.
- `nickel-ni.rkt`: Nickel-style noninterference policy and
  checking, using the Serval noninterference library.

The state-machine specifications themselves are in `spec.rkt`.

For experimentation, you can run without the `split-pc` optimization
described in the paper
by passing `--disable-split-pc` before `--verify`, but in practice
this will cause most verification tasks to fail due to timeout.

## Keystone analysis

The paper describes our approach of using Serval to validate
the design of the Keystone software enclave monitor.
The state-machine specification is located in `monitors/keystone/verif/spec.rkt`,
and the noninterference-like safety specification is in `monitors/keystone/verif/ni.rkt`.
You can run the design validation with:

```bash
# Run Keystone design verification (~ 3 sec.)
$ racket scripts/run.rkt --verify keystone
```

Example expected output:

```
cpu time: 108 real time: 459 gc time: 37
0
  5 monitors/keystone/verif/ni.rkt
5 tests passed
```

## BPF JIT symbolic testing

The paper describes the application of Serval to find and fix
15 previously unknown bugs in the RV64 and x86-32 Linux BPF JIT compilers.
The code for the JIT compilers and their verification can be
found under `bpf/jit`.  Common JIT definitions and a generic specification
for BPF JIT correctness are found in `bpf/jit/common.rkt`. The BPF JIT
implementations for RV64 and x86-32 are located in `bpf/jit/riscv64.rkt`
and `bpf/jit/x32.rkt`, respectively. You can run the symbolic test
cases for the BPF JIT with:

```bash
# Run BPF JIT verification (~ 1 min.)
$ racket scripts/run.rkt --bpf
```

This will run the BPF JIT test cases for x86-32, RV64, and RV32.
The end of the expected output is the following:

```
  14 bpf/jit/test/riscv32-alu32-x.rkt
  12 bpf/jit/test/riscv64-alu64-x.rkt
  11 bpf/jit/test/x32-alu32-x.rkt
  10 bpf/jit/test/riscv32-alu64-x.rkt
  10 bpf/jit/test/riscv64-alu32-x.rkt
  10 bpf/jit/test/x32-alu32-k.rkt
  10 bpf/jit/test/x32-alu64-x.rkt
   9 bpf/jit/test/riscv32-alu32-k.rkt
   9 bpf/jit/test/riscv32-alu64-k.rkt
   9 bpf/jit/test/x32-alu64-k.rkt
   6 bpf/jit/test/riscv64-alu32-k.rkt
   6 bpf/jit/test/riscv64-alu64-k.rkt
116 tests passed
```

Below are links to upstreamed patches in the Linux kernel for
the bugs caught using symbolic testing as described in the paper,
and the new test cases added.

- <https://git.kernel.org/linus/1e692f09e091>
- <https://git.kernel.org/linus/46dd3d7d287b>
- <https://git.kernel.org/linus/68a8357ec15b>
- <https://git.kernel.org/linus/6fa632e719ee>
- <https://git.kernel.org/linus/ac8786c72eba>

## Experimental results in tables

Figures 6 and 8 in the paper show lines of code and
verification performance for the Serval framework and
the security monitors. These tables in the paper can be replicated
with the following:

```bash
# Print table data (~ 40 min.)
$ racket scripts/run.rkt --tables
```

An example of the output is shown below:

```
===FIGURE 6===

component                          lines of code
--------------------------------------------------
Serval framework                          1,244
RISC-V verifier                           1,036
x86-32 Verifier                             856
LLVM verifier                               789
BPF Verifier                                472
--------------------------------------------------
total                                     4,397

===FIGURE 8===
                             CertiKOS    Komodo
lines of code:
  implementation                1,988     2,310
  abs. function + rep. inv        438       439
  state-machine spec              124       445
  safety                          297       578
verification time (s):
  refinement proof (-O0)          127       351
  refinement proof (-O1)          148       415
  refinement proof (-O2)          161       367
  safety proof                     57       596
  ```

Note that these performance results are for a machine with
4 CPU cores; running with fewer cores or a different hardware
configuration can produce vastly different results.

[Rosette]: https://emina.github.io/rosette/
[Spike]: https://github.com/riscv/riscv-isa-sim