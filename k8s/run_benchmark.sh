#!/bin/bash

set -e

# Experiment variables
ROOT_DIR=/code/experiment-lammps-native
CLUSTER_SIZE=5
MPI_PROCS_PER_NODE=5
echo "----------------------------------------"
echo "       LAMMPS Native k8s Benchmark      "
echo "                                        "
echo "Benchmark parameters:                   "
echo "    - K8s Cluster Size: ${CLUSTER_SIZE} "
echo "    - Max. MPI processes per node: ${MPI_PROCS_PER_NODE}"
echo "----------------------------------------"

# Deploy and resize cluster
# kubectl apply -f ${ROOT_DIR}/k8s/deployment.yaml
# kubectl scale --replicas=${CLUSTER_SIZE} -f ${ROOT_DIR}/k8s/deployment.yaml

# Generate the corresponding host file
source ./k8s/gen_host_file.sh
echo "----------------------------------------"

# Copy the run batch script just in case we have changed something (so that we
# don't have to rebuild the image)
sudo microk8s kubectl cp ./k8s/run_batch.sh ${MPI_MASTER}:/home/mpirun/

# Run the benchmark at the master
sudo microk8s \
    kubectl exec -it \
    ${MPI_MASTER} -- bash -c "su mpirun -c '/home/mpirun/run_batch.sh'"
echo "----------------------------------------"

# Grep the results
sudo microk8s kubectl cp ${MPI_MASTER}:/home/mpirun/lammps_native_k8s.log \
    lammps_native_k8s.log
