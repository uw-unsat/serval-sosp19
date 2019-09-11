FROM ubuntu:19.04

RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    bc \
    bc \
    bison \
    build-essential \
    clang \
    cloc \
    curl \
    device-tree-compiler \
    flex \
    gawk \
    gcc \
    gcc-riscv64-linux-gnu \
    git \
    gperf \
    libattr1-dev \
    libcap-dev \
    libexpat-dev \
    libfdt-dev \
    libglib2.0-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libncurses-dev \
    libpixman-1-dev \
    libtool \
    libusb-1.0-0-dev \
    llvm \
    make \
    patchutils \
    pkg-config \
    python \
    python-pip \
    python3 \
    texinfo \
    vim \
    wget \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /code

RUN wget 'https://mirror.racket-lang.org/installers/7.3/racket-7.3-x86_64-linux.sh' && \
    chmod +x ./racket-7.3-x86_64-linux.sh && \
    echo 'yes\n1' | ./racket-7.3-x86_64-linux.sh && \
	rm -f racket-7.3-x86_64-linux.sh

# Install QEMU
RUN git clone 'https://github.com/qemu/qemu.git' && \
    cd qemu && \
    git checkout 'v4.0.0' && \
    ./configure \
        --disable-gtk \
        --disable-opengl \
        --disable-sdl \
        --disable-vnc \
        --disable-vte \
        --enable-kvm \
        --enable-virtfs \
        --target-list=riscv64-softmmu,riscv32-softmmu,x86_64-softmmu && \
    make -j4 && make install && \
    cd /code && rm -rfv qemu

# Install Unicorn
RUN git clone 'https://github.com/unicorn-engine/unicorn.git' && \
    cd unicorn && \
    env UNICORN_ARCHS="x86" ./make.sh && \
    env UNICORN_ARCHS="x86" ./make.sh install && \
    cd /code && rm -rfv unicorn

# Install Rosette
RUN git clone 'https://github.com/emina/rosette.git' && \
    cd rosette && \
    raco pkg install --auto -i --no-setup && raco setup -Dl rosette

# Install riscv-fesvr
RUN git clone 'https://github.com/riscv/riscv-fesvr.git' && \
    cd riscv-fesvr && \
    mkdir build && \
    cd build && \
    ../configure --prefix=/opt/riscv --target=riscv64-unknown-elf && \
    make -j4 && \
    make install && \
    cd /code && rm -rfv riscv-fesvr

# Install Spike
RUN git clone 'https://github.com/riscv/riscv-isa-sim.git' && \
    cd riscv-isa-sim && \
    mkdir build && cd build && \
    ../configure --prefix=/opt/riscv --with-fesvr=/opt/riscv && \
    make -j4 && make install && \
    cd /code && rm -rfv riscv-isa-sim && \
    ln -s /opt/riscv/bin/spike /usr/bin/spike

RUN pip install parcon

ADD . /serval

RUN raco pkg install /serval/serval

# Set /serval to default working directory
WORKDIR /serval