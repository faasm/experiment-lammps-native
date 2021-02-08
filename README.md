# Native execution of LAMMPS

This repo contains the image, deployment files, and scripts to run
[LAMMPS](https://lammps.sandia.gov/) natively and benchmark its execution in
k8s.

In particular, the image installs the software and OpenMPI, and sets up the SSH
server so that multi-host MPI execution can be replicated in different
containers.

## Build the image

There's a single image to be built to run this experiments. You can inspect
the source code at `docker/experiment-lammps-native.dockerfile`, and build it
running (this may take a while the first time):
```
./docker/build/lammps.sh
```

Alternatively, you can pull it directly from docker hub:
```
docker pull faasm/experiment-lammps-native
```

## Deployment

Currently running on the `koala5` machines with 10 CPUs and 2 cores per CPU.
You can customize the number of available processes per CPU (assuming you don't
turn on HW threads) by modifying the `slots` parameter in the hostfile.

### Docker Compose

First start the cluster:
```
docker-compose up -d
```

Exec into the master container:
```
docker-compose exec --user mpirun master /bin/bash
```

Copy the example file, compile it and run it:
```
cp /code/examples/experiment-lammps-native/examples/mpi_helloworld.c .
mpicc mpi_helloworld.c -o helloworld
scp helloworld worker:
mpirun -np 5 --hostfile hostfile helloworld
```

### K8s

In order to run the deployment, you just need to run the command below. This
will initialize a cluster with 5 MPI workers. Feel free to change the number
of replicas by editing the `yaml` file.
```
kubectl apply -f k8s/deployment.yaml
```
Alternatively, to scale the experiment once deployed, you may run:
```
kubectl scale --replicas=<NEW_REPLICA_COUNT> -f ./k8s/deployment.yaml
```

Once you are confident of the size of your cluster, you can create the hostfile
for the MPI deployment. By default, this will fix the `slots` parameter (i.e.
how many MPI processes may run per worker) to 4.
```
./k8s/gen_host_file.sh
```
If you want to run with a different `slots` value, you can use an env variable:
```
export MPI_MAX_PROC=<NEW_VALUE> ./k8s/gen_host_file.sh
```

You may now exec directly into the master pod using, remember to switch to the
`mpirun` user to run tests manually or ssh into other pods (otherwise the SSH
config won't work).
```
kubectl exec -it <MPI_MASTER_NAME> -- bash
su mpirun
```

To stop the execution just run:
```
kubectl delete -f ./k8s/deployment.yaml
```

### Benchmark

To run the benchmark, just execute (from your terminal):
```
k8s/run_benchmark.sh
```
