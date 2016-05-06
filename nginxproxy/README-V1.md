# (Deprecated) Docker compose V1 file example for setting up an Artifactory HA cluster
## Please see README.md for the V2 version 

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
You should set the env variable $art_licenses to the path on the docker host where are located the licenses :
    
    export art_licenses=/home/myuser/mylicenses

Put your HA licenses in `$art_licenses/artifactory-H1.lic` and `$art_licenses/license/artifactory-H2.lic`

### 3. Aliasing the ip machine

    echo "$(docker-machine ip fusion) artifactory-cluster" | sudo tee -a /etc/hosts

## Launching
You should choose a namespace associated with this demo :
    
    export namespace=mydemo

    docker-compose -f docker-compose-v1.yml up

Without logs
    
    docker-compose -f docker-compose-v1.yml up -d

And then, your own artifactory cluster should be available :

https://artifactory-cluster/artifactory

## Usefull commands
Ssh into container 

    docker exec -ti container_id /bin/bash

Print logs:   

    docker logs container_id

## Managing the lifecycle

### Restarting 
Without any data loss, you can safely restart the cluster with

    docker-compose -f docker-compose-v1.yml restart

or by CTRL+C and then

    docker-compose -f docker-compose-v1.yml up

### Restarting from scratch
Rebuild and restart with fresh data :
    
    docker-compose -f docker-compose-v1.yml stop
    docker-compose -f docker-compose-v1.yml rm
    docker-compose -f docker-compose-v1.yml build
    docker-compose -f docker-compose-v1.yml up

### Restarting with existing data
We delete all the non-data containers :

    docker-compose -f docker-compose-v1.yml stop
    docker rm artifactorysc_1-mydemo artifactorysc_2-mydemo mysqlsc-mydemo nginxsc-mydemo
    docker-compose up -f docker-compose-v1.yml

### Saving data
TODO

