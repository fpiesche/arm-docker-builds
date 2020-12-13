#!/bin/bash

NODEID_REGEXP='NodeID"\:"(\K\w+)'
IPADDR_REGEXP='Addr":"(\K[\d\.]+)(?=")'

if [[ -z ${DOCKER_SOCKET} ]]; then
    DOCKER_SOCKET="/var/run/docker.sock"
fi

if [[ -z ${PORTS} ]]; then
    echo "No ports defined to forward! Please set the PORTS environment variable to a space separated list of ports to open."
    exit 1
fi
if [[ -z ${SERVICE} ]]; then
    echo "No service defined to forward ports for! Please set the SERVICE environment variable to the name of a service."
    exit 1
fi

service_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/tasks" --data-urlencode 'filters={"service":{"'"${SERVICE}"'":true}}')
if [[ -z $service_spec ]]; then
    echo "Failed to find service ${SERVICE}!"
    exit 1
fi

node_id=$(echo $service_spec | grep -Po ${NODEID_REGEXP})
if [[ -z $node_id ]]; then
    echo "Failed to find node ID for ${SERVICE}!"
    exit 1
else
    echo "Service ${SERVICE} found on node ${node_id}."
fi

node_ip=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/nodes/${node_id}" | grep -Po ${IPADDR_REGEXP})
if [[ -z $service_spec ]]; then
    echo "Failed to find IP address for node ${node_id}!"
    exit 1
fi

for port in ${PORTS}; do
    echo "Forwarding port ${port} to ${node_ip}..."
    upnpc -a ${node_ip} ${port} ${port} TCP -e "Docker service ${SERVICE}"
done
