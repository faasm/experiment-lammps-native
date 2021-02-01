#!/bin/bash

set -e

THIS_DIR=$(dirname $(readlink -f $0))
PROJ_ROOT=${THIS_DIR}/..
LAMMPS_DIR=${PROJ_ROOT}/lammps
LAMMPS_BUILD_DIR=${LAMMPS_DIR}/build

${LAMMPS_BUILD_DIR}/lmp $1 $2
