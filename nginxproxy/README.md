# nginxproxy
This docker-compose file will demonstrate the auto sync of nginx configurations from artifactory HA cluster.

For the moment, the docker-compose file only starts a HA cluster with a shared volume instead of NFS. It doesn't depend on any internal repository.
The data volumes are not shared with the host for simplicity sake (lot of permissions issues involved).

## Prerequisites

Docker 1.9, either native or with docker-machine (Toolbox on Windows or Mac OS X : https://www.docker.com/docker-toolbox)

### 1. Create a big docker-machine on local vmware
For the first time, create a boot2docker VM with the following command line :

    docker-machine create --driver vmwarefusion --vmwarefusion-cpu-count 2 --vmwarefusion-disk-size 80000 --vmwarefusion-memory-size 4096 fusion

    # Tell the docker command line to use this machine
    eval "$(docker-machine env fusion)"

    # Should work
    docker ps

### 2. Setup licenses
Put your HA licenses in $HOME/license/artifactory-H1.lic and $HOME/license/artifactory-H2.lic

### 3. Aliasing the ip machine

    echo "$(docker-machine ip fusion) artifactory-cluster" | sudo tee -a /etc/hosts

## Launching

    docker-compose up

And then, your own artifactory cluster should be available :

https://artifactory-cluster/artifactory
