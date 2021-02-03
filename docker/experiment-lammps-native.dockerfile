FROM faasm/grpc-root:0.0.16

# Download and install OpenMPI
WORKDIR /tmp
RUN wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.0.tar.bz2
RUN tar xf openmpi-4.1.0.tar.bz2
WORKDIR /tmp/openmpi-4.1.0
RUN ./configure --prefix=/usr/local
RUN make -j `nproc`
RUN make install
# The previous steps takes a lot, so don't move these lines

# Add an mpirun user
ENV USER mpirun
RUN adduser --disabled-password --gecos "" ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up SSH
RUN apt update && apt upgrade -y
RUN apt install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:${USER}' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Download LAMMPS code
WORKDIR /code
RUN git clone -b master https://github.com/faasm/lammps

# Prepare code (the below trick ensures not caching and re-cloning)
ARG FORCE_RECREATE=unknown
RUN apt install -y gdb vim 
RUN git clone https://github.com/faasm/experiment-lammps-native
WORKDIR /code/experiment-lammps-native

# Compile LAMMPS
RUN ./build/lammps.sh

# Patches (order when it works)
ENV HOME /home/${USER}
WORKDIR ${HOME}/.ssh
COPY ./ssh/config config
COPY ./ssh/id_rsa.mpi id_rsa
COPY ./ssh/id_rsa.mpi.pub id_rsa.pub
COPY ./ssh/id_rsa.mpi.pub authorized_keys
RUN ssh-keygen -A
RUN chmod -R 600 ${HOME}/.ssh* && \
    chmod 700 ${HOME}/.ssh && \
    chmod 644 ${HOME}/.ssh/id_rsa.pub && \
    chmod 664 ${HOME}/.ssh/config && \
    chown -R ${USER}:${USER} ${HOME}/.ssh
WORKDIR ${HOME}

# Start the SSH server for reachability
CMD ["/usr/sbin/sshd", "-D"]
