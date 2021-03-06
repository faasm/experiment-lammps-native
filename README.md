# Native execution of LAMMPS

This repo contains the image, deployment files, and scripts to run
[LAMMPS](https://lammps.sandia.gov/) natively and benchmark its execution in
k8s.

In particular, the image installs the software and OpenMPI, and sets up the SSH
server so that multi-host MPI execution can be replicated in different
containers.

=============

## Quick Start

To get the benchmark up and running quickly, do just the following.
This assumes:
* You have configured the `az` Azure client ([see here](#az-setup)).

Then to run the benchmark in an Azure k8s cluster:
```
aks/run_benchmark.sh
```

This should populate the folder in `./results`. Then generate the plots using:
```
cd plots && gnuplot lammps_k8s.gnuplot && cd -
```

==========

## Step by step walkthrough

### Build the image

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

### Run on Docker Compose

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

### Run on microk8s

In order to run the deployment, you just need to run the command below. This
will initialize a cluster with 5 MPI workers. Feel free to change the number
of replicas by editing the `yaml` file.
```
microk8s kubectl apply -f k8s/deployment.yaml
```
Alternatively, to scale the experiment once deployed, you may run:
```
microk8s kubectl scale --replicas=<NEW_REPLICA_COUNT> -f ./k8s/deployment.yaml
```

Once you are confident of the size of your cluster, you can run the benchmark:
```
./k8s/run_benchmark.sh
```

To replicate what the benchmarking script does, you first create the hostfile
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

### Azure Benchmarks Set-Up <a name="az-setup">

To run the experiments at the Azure cluster, you need to set up the azure
client (`az`).

Steps taken:
1. Installation and login 
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login # use IMP credentials
# set the account to the LSDS one
az account set -s e594b650-46d3-4375-be21-2ea11e8ed741
```

**All the remaining steps were already done once, and shouldn't need to be
done again. Kept here for future reference.**

2. **OPTIONAL**: Create container registry

First, the following registries need to be enabled: `Microsoft.ContainerInstance`,
`Microsoft.ContainerRegistry`, and `Microsoft.ContainerService`. To check
whether these are enabled or not, you may use:
```
az provider show --namespace Microsoft.ContainerInstance | head -20
```

Then, you can create the container registry and login:
```
az acr create --resource-group faasm --name faasmcr --sku Basic
az acr login --name faasmcr
```

Now you may tag and push your images as you'd do with any other container
registry service. First, though, you need to query for the login server URL:
```
azure acr list --resource-group faasm --query "[].{acrLoginServer:loginServer}" --output table
# faasmcr.azurecr.io at the time of the writing

# Tag the image
docker tag <img> faasmcr.azurecr.io/<img>

# Push it
docker push faasmcr.azurecr.io/<img>

# Check that it uploaded sucesfully
az acr repository list --name faasmcr --output table
```

3. Create a k8s cluster:

The next command fails to attach to the ACR as it requires owner privileges.
I'll wait I can circumvent it somehow.
```
az aks create --resource-group faasm --name faasmCluster --node-count 2 --generate-ssh-keys --atach-acr faasmcr

# Get the credentials
az aks get-credentials --resource-group faasm --name faasmCluster

# Check that the nodes are ready
kubectl get nodes
```

As we can't programmatically link with the ACR due to lack of privileges, we
can manually generate a secret for AKS to pull from ACR:
```
az acr update -n faasmcr --admin-enabled-true

ACR_NAME=faasmcr
ACR_UNAME=$(az acr credential show -n $ACR_NAME --query="username" -o tsv)
ACR_PASSWD=$(az acr credential show -n $ACR_NAME --query="passwords[0].value" -o tsv)

kubectl create secret docker-registry acr-secret \
  --docker-server="$ACR_NAME.azurecr.io" \
  --docker-username=$ACR_UNAME \
  --docker-password=$ACR_PASSWD \
```

4. Deploy application and run benchmark:
```
kubectl apply -f aks/deployment.yaml

./aks/run_benchmark.sh
```

5. To reduce the cost while the cluster is idle, you may stop it when you
use it no more.


## Running on an Azure VM Scale Set (Bare Metal)

**Important: delete the cluster as you are done with it, otherwise we will
be charged _a lot_.**

I'd also recommend opening the Azure portal on the browser to check the current
cost and allocated resources.

To bootstrap the cluster just run:
```
./az-vm/az_vms.sh create <NUM_VMs>
```

You can check through the portal this creates a VM Scale Set with `<NUM_VMs>`
instances.
It also creates additional resources for cluster maintenance.

To run the benchmarks just do:
```
./az-vm/run_benchmark.sh
```
which should create a data file under `./results`.

Lastly to deallocate all resources run:
```
./az-vm/az_vms.sh delete
```
and delete through the browser the remaining components (veth, LBs, ...).

#### Troubleshooting Execution

It seems as though MPI does not like running with `np > vCPUs`. Granted it's
not MPI _in general_ rather than LAMMPS may be too resource eager (?). Then,
you must make sure that:
* You run with `MPI_MAX_PROC <= $(nproc)`
* Each pod is assigned at a different node. This is set in the deployment file
but you can sanity check it using `kubectl get pods -o wide`.
