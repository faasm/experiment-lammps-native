FROM faasm/grpc-root:0.0.16

# Download and install OpenMPI
WORKDIR /tmp
RUN wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.0.tar.bz2
RUN tar xf openmpi-4.1.0.tar.bz2
WORKDIR /tmp/openmpi-4.1.0
RUN ./configure
RUN make -j `nproc`
RUN make install

# Download LAMMPS code
WORKDIR /code
RUN git clone -b master https://github.com/faasm/lammps

# Prepare code
ARG FORCE_RECREATE=unknown
RUN git clone https://github.com/faasm/experiment-lammps-native
WORKDIR /code/experiment-lammps-native

# Compile LAMMPS
RUN ./build/lammps.sh
