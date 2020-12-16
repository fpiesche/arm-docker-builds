#!/bin/bash

NODEID_REGEXP='NodeID"\:"(\K\w+)'
IPADDR_REGEXP='Addr":"(\K[\d\.]+)(?=")'

if [[ -z ${DOCKER_SOCKET} ]]; then
    DOCKER_SOCKET="/var/run/docker.sock"
fi
if [[ -z ${UPDATE_FREQ} ]]; then
    UPDATE_FREQ=60
fi

if [[ -z ${PORTS} ]]; then
    echo "===== No ports defined to forward! Please set the PORTS environment variable to a space separated list of ports to open."
    exit 1
fi
if [[ -z ${SERVICE} ]]; then
    echo "===== No service defined to forward ports for! Please set the SERVICE environment variable to the name of a service."
    exit 1
fi

while true; do
    current_forwards=$(upnpc -L)

    service_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/tasks" --data-urlencode 'filters={"service":{"'"${SERVICE}"'":"true"},"desired-state":{"running":"true"}}')

    if [[ ! -z ${DEBUG} ]]; then
        echo "===== Service spec: $(echo ${service_spec})"
    fi

    if [[ -z ${service_spec} ]]; then
        echo "===== Failed to find service ${SERVICE}!"
        exit 1
    fi

    node_id=$(echo ${service_spec} | grep -Po ${NODEID_REGEXP})
    if [[ -z ${node_id} ]]; then
        echo "===== Failed to find node ID for ${SERVICE}!"
        exit 1
    else
        echo "===== Service ${SERVICE} found on node ${node_id}."
    fi

    node_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/nodes/${node_id}")
    if [[ ! -z ${DEBUG} ]]; then
        echo "===== Node spec: $(echo ${node_spec})"
    fi

    node_ip=$(echo ${node_spec} | grep -Po ${IPADDR_REGEXP})
    if [[ -z ${node_ip} ]]; then
        echo "===== Failed to find IP address for node ${node_id}!"
        exit 1
    else
        echo "===== IP address for ${node_id} is ${node_ip}."
    fi

    for port in ${PORTS}; do
        current_ip=$(echo ${current_forwards} | grep -Po ".*TCP\s+${port}->(\K[\d\.]+)")
        if [[ -z ${current_ip} ]] || [[ ${node_ip} != ${current_ip} ]]; then
            if [[ -z ${current_ip} ]]; then
                echo "===== Port ${port} not currently forwarded."
            else
                echo "===== Port ${port} currently forwarded to ${current_ip}, removing..."
                upnpc -d ${port} TCP
            fi
            echo "===== Forwarding port ${port} to ${node_ip}..."
            upnpc -a ${node_ip} ${port} ${port} TCP -e "Docker service ${SERVICE}"
        else
            echo "===== Port ${port} correctly forwarded to ${node_ip}, nothing to do."
        fi
    done

    echo "===== Waiting for next update..."
    sleep ${UPDATE_FREQ}
done