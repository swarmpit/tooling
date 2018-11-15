#!/bin/bash

display_usage() {
	echo "This script creates specified number of manager and worker swarm nodes"
	echo -e "\nUsage:\n swarm-create.sh [#manager_nodes] [#worker_nodes]"
  echo -e "\n example: swarm-create.sh 1 2"
	}
if [  $# -le 1 ]
	then
		display_usage
		exit 1
	fi

manager_nodes=$1
worker_nodes=$2
total_nodes=`expr $manager_nodes + $worker_nodes`

echo "### Creating $total_nodes nodes ($manager_nodes managers, $worker_nodes workers). Please be patient."
for (( c=1; c<=$total_nodes; c++ ))
do
    docker-machine create --virtualbox-boot2docker-url https://github.com/boot2docker/boot2docker/releases/download/v18.06.0-ce/boot2docker.iso  node$c
done

# Get IP from leader node
leader_ip=$(docker-machine ip node1)

# Init Docker Swarm mode
echo "### Initializing Swarm mode ..."
eval $(docker-machine env node1)
echo "Leader address $leader_ip"
docker swarm init --advertise-addr $leader_ip

docker-machine ssh node1  "git clone https://github.com/swarmpit/swarmpit; \
                            docker stack deploy -c swarmpit/docker-compose.yml swarmpit"

# Swarm tokens
manager_token=$(docker swarm join-token manager -q)
worker_token=$(docker swarm join-token worker -q)

# Joinig manager nodes
echo "### Joining manager modes ..."
for (( c=1; c<=$manager_nodes; c++ ))
do
    eval $(docker-machine env node$c)
    docker swarm join --token $manager_token $leader_ip:2377
done

# Join worker nodes
echo "### Joining worker modes ..."
for (( c=1; c<=$worker_nodes; c++ ))
do
    eval $(docker-machine env node$c)
    docker swarm join --token $worker_token $leader_ip:2377
done

# Clean Docker client environment
echo "### Cleaning Docker client environment ..."
eval $(docker-machine env -u)
