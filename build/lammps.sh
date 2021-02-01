#!/bin/bash

set -e

THIS_DIR=$(dirname $(readlink -f $0))
PROJ_ROOT=${THIS_DIR}/..
LAMMPS_DIR=${PROJ_ROOT}/lammps
LAMMPS_BUILD_DIR=${LAMMPS_DIR}/build

mkdir -p ${LAMMPS_BUILD_DIR}

pushd ${LAMMPS_BUILD_DIR} >> /dev/null

cmake -GNinja \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_COMPILER=/usr/bin/clang-10 \
    -DCMAKE_CXX_COMPILER=/usr/bin/clang++-10 \
    -DCMAKE_INSTALL_PREFIX=/code/lammps/install-native \
    ../cmake

ninja

popd >> /dev/null

