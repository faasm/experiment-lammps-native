#!/bin/bash

set -e

mpirun -np ${MPI_NP:-"4"} --hostfile hostfile \
    /code/lammps/build/lmp \
    -in /code/lammps/examples/controller/in.controller.wall > out.log

if [[ $? -eq 0 ]]; then
    result_min=$(tail -1 out.log | cut -d' ' -f4- | cut -d':' -f2)
    result_sec=$(tail -1 out.log | cut -d' ' -f4- | cut -d':' -f3)
    result=$((10#$result_min * 60 + 10#$result_sec))
    #echo "${MPI_NP} $result" >> lammps_native_k8s.log
    echo $result
fi
