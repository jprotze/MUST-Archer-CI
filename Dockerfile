FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

RUN apt-get update \
    && apt-get -y -qq --no-install-recommends install \
    curl \
    binutils-dev \
    make \
    automake \
    autotools-dev \
    autoconf \
    libtool \
    zlib1g \
    zlib1g-dev \
    libatomic1 \
    libcurl4-openssl-dev \
    libfabric-dev \
    mpich \
    libmpich-dev \
    libopenmpi-dev \
    libxml2-dev \
    python3 \
    python3-pip \
    python3-venv \
    gfortran \
    gcc \
    g++ \
    git \
    graphviz \
    libgtest-dev \
    clang \
    libomp-dev \
    llvm-dev \
    lldb \
    clangd \
    clang-format \
    clang-tidy \
    ninja-build \
    vim \
    ccache \
    openssh-client \
    libssl-dev \
    gdb \
    googletest \
    wget \
    libmkl-core \
    libmkl-dev \
    libmkl-meta-computational \
    libmkl-meta-interface \
    libmkl-meta-threading \
    && apt-get -yq clean \
    && rm --recursive --force /var/lib/apt/lists/*


COPY requirements.txt .

# Install Python dependencies and ensure to activate virtualenv (by setting PATH variable)
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip3 install --no-input --no-cache-dir --disable-pip-version-check -r /requirements.txt

# Install CMake
RUN mkdir -p /external && cd /external && \
      wget https://github.com/Kitware/CMake/releases/download/v3.27.1/cmake-3.27.1.tar.gz && \
      tar xf cmake-3.27.1.tar.gz && \
      cd cmake-3.27.1/ && \
      ./bootstrap --parallel=$(nproc) --prefix=/usr && \
      make -j$(nproc) && \
      make -j$(nproc) install && \
      cd /external && \
      rm -rf /external/*

# Install LLVM
RUN mkdir -p /external && cd /external && \
      git clone -b 15.x-fiber https://github.com/jprotze/llvm-project.git && \
      cd llvm-project && mkdir BUILD && cd BUILD && \
      CC=clang CXX=clang++ cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_LINKER=$(which ld)\
            -DCMAKE_INSTALL_PREFIX=/opt/llvm \
            -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
            -DLLVM_ENABLE_LIBCXX=ON \
            -DCLANG_DEFAULT_CXX_STDLIB=libstdc++ \
            -DLLVM_BINUTILS_INCDIR=/usr/include \
            -DLLVM_ENABLE_PROJECTS="clang;compiler-rt;clang-tools-extra;openmp" \
            -DLLVM_ENABLE_RUNTIMES="libunwind" \
            -DLLVM_INSTALL_UTILS=ON \
            -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
            ../llvm && \
      ninja install && \
      cd /external && \
      rm -rf /external/*

ENV MPICH_CC=/opt/llvm/bin/clang
ENV MPICH_CXX=/opt/llvm/bin/clang++
ENV OMPI_CC=/opt/llvm/bin/clang
ENV OMPI_CXX=/opt/llvm/bin/clang++
ENV LD_LIBRARY_PATH=/opt/llvm/lib/x86_64-unknown-linux-gnu:/opt/llvm/lib:$LD_LIBRARY_PATH

# Install MUST
RUN mkdir -p /external && cd /external && \
      wget https://hpc.rwth-aachen.de/must/files/MUST-v1.9.1-tsan-shim.tar.gz && \
      tar xf MUST-v1.9.1-tsan-shim.tar.gz && \
      cd MUST-v1.9.1-tsan-shim && \
      mkdir BUILD-mpich && cd BUILD-mpich && \
      CC=mpicc.mpich CXX=mpicxx.mpich \
      cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/MUST/mpich/ \
      -DMPI_CXX_LINK_FLAGS="-flto=auto" -DMPI_C_LINK_FLAGS="-flto=auto" \
      -DMPI_C_COMPILER=$(which mpicc.mpich) -DMPI_CXX_COMPILER=$(which mpicxx.mpich) \
      -DMPI_Fortran_COMPILER=$(which mpif90.mpich) -DMPIEXEC_EXECUTABLE=$(which mpiexec.mpich) && \
      ninja install && ninja install-prebuilds && \
      mkdir ../BUILD-openmpi && cd ../BUILD-openmpi && \
      CC=mpicc.openmpi CXX=mpicxx.openmpi FC=mpif90.openmpi \
      cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/MUST/openmpi/ -DMPI_C_COMPILER=$(which mpicc.openmpi) -DMPI_CXX_COMPILER=$(which mpicxx.openmpi) -DMPI_Fortran_COMPILER=$(which mpif90.openmpi) -DMPIEXEC_EXECUTABLE=$(which mpiexec.openmpi) && \
      ninja install && ninja install-prebuilds && \
      cd /external && \
      rm -rf /external/*
      
RUN pip3 install --no-input --no-cache-dir --disable-pip-version-check https://apps.fz-juelich.de/jsc/jube/jube2/download.php?version=latest

WORKDIR /

# Run as non-privileged user
RUN     useradd -ms /bin/bash user
COPY code .
#RUN	chown -R user code

WORKDIR /home/user
USER user

