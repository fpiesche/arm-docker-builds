#!/bin/bash

NODEID_REGEXP='NodeID"\:"(\K\w+)'
IPADDR_REGEXP='\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
IGD_DEVICE_REGEXP="(\Khttp.*.xml)"

if [[ -z ${PORTS} ]]; then
    echo "===== No ports defined to forward! Please set the PORTS environment variable to a space separated list of ports to open."
    exit 1
fi
if [[ -z ${SERVICE} ]]; then
    echo "===== No service defined to forward ports for! Please set the SERVICE environment variable to the name of a service."
    exit 1
fi

while true; do
    if [[ -z ${IGD_DEVICE_URL} ]]; then
        echo "===== Trying to find IGD device..."
        IGD_DEVICE_URL=$(upnpc -L | grep -Po ${IGD_DEVICE_REGEXP})
    fi
    if [[ -z ${IGD_DEVICE_URL} ]]; then
        echo "===== Failed to find an IGD device on the network! Try specifying the URL using the IGD_DEVICE_URL environment variable."
        exit 1
    fi

    echo "===== Getting current UPNP port mappings from ${IGD_DEVICE_URL}..."
    current_forwards=$(upnpc -u ${IGD_DEVICE_URL} -L)

    echo "===== Getting service spec for ${SERVICE}..."
    service_spec=$(curl --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/tasks" --data-urlencode 'filters={"service":{"'"${SERVICE}"'":true},"desired-state":{"running":true}}')

    if [[ ! -z ${DEBUG} ]]; then
        echo "===== Service spec: $(echo ${service_spec})"
    fi

    if [[ ! -z ${service_spec} ]]; then
        node_id=$(echo ${service_spec} | grep -Po ${NODEID_REGEXP})
        if [[ -z ${node_id} ]]; then
            echo "===== Failed to find node ID for ${SERVICE}!"
            if [[ ! -z ${FAIL_ON_MISSING_SERVICE} ]]; then
                exit 1
            fi
        else
            echo "===== Service ${SERVICE} found on node ${node_id}."
        fi
    fi

    if [[ ! -z ${node_id} ]]; then
        node_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/nodes/${node_id}")
        if [[ ! -z ${DEBUG} ]]; then
            echo "===== Node spec: $(echo ${node_spec})"
        fi

        for ip in $(echo ${node_spec} | grep -Po ${IPADDR_REGEXP}); do
            if [[ ${ip} != "0.0.0.0" ]]; then
                node_ip=${ip}
            fi
        done
        if [[ -z ${node_ip} ]]; then
            echo "===== Failed to find IP address for node ${node_id}!"
            if [[ ! -z ${FAIL_ON_MISSING_SERVICE} ]]; then
                exit 1
            fi
        else
            echo "===== IP address for ${node_id} is ${node_ip}."
        fi
    fi

    if [[ ! -z ${node_ip} ]]; then
        for port in ${PORTS}; do
            current_ip=$(echo ${current_forwards} | grep -Po ".*TCP\s+${port}->(\K[\d\.]+)")
            if [[ -z ${current_ip} ]] || [[ ${node_ip} != ${current_ip} ]]; then
                if [[ -z ${current_ip} ]]; then
                    echo "===== Port ${port} not currently forwarded."
                else
                    echo "===== Port ${port} currently forwarded to ${current_ip}, removing..."
                    upnpc -u ${IGD_DEVICE_URL} -d ${port} TCP
                fi
                echo "===== Forwarding port ${port} to ${node_ip}..."
                upnpc -u ${IGD_DEVICE_URL} -a ${node_ip} ${port} ${port} TCP -e "Docker service ${SERVICE}"
            else
                echo "===== Port ${port} correctly forwarded to ${node_ip}, nothing to do."
            fi
        done
    fi

    echo "===== Waiting for next update cycle..."
    sleep ${UPDATE_FREQ}
done