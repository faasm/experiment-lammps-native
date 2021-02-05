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

Generate the hostfile:
```
./k8s/gen_host_file.sh
```

You may now exec directly into the master pod using:
```
kubectl exec -it ${MPI_MASTER} -- bash
```

To stop the execution just run:
```
kubectl stop -f ./k8s/deployment.yaml
```

### SCS's message

wahey! nice. i think the right k8s abstraction is a deployment, which should have a scale parameter or something that specifies how many containers it has. this is useful for automated experiments as you can use the k8s API to change the scale (and thus vary the number of MPI workers). you can also play around with the parameters of a deployment to make sure containers aren't placed on the same host for example.
the end goal with this is to have an automated experiment that will run the same lammps job different numbers of MPI workers (and plot a graph of number of workers vs run time). i don't know if we can just create an MPI cluster with the max number of workers and use mpirun parameters to do this, or if it's better to actually limit the resources available using the scale of the k8s deployment. i think the latter is better, as it gives us more control and ensures MPI isn't doing anything funky (plus we can try to break it)
we may also want to do experiments to demonstrate multi-tenancy or sequential execution of jobs, so we might want to execute multiple MPI jobs on the same limited number of workers, so it would be useful to be able to vary the scale through the API for that too. (edited)
