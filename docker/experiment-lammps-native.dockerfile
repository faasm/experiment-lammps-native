FROM faasm/grpc-root:0.0.16

# Prepare code
WORKDIR /code
RUN git clone https://github.com/faasm/experiment-lammps-native
WORKDIR /code/experiment-lammps-native
RUN git clone https://github.com/faasm/lammps

# Compile LAMMPS
RUN ./build/lammps.sh
