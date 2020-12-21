#!/bin/bash

NODEID_REGEXP='NodeID"\:"(\K\w+)'
IPADDR_REGEXP='\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
IGD_DEVICE_REGEXP="(\Khttp.*.xml)"
SERVICE_NAME_REGEXP='"Spec":{"Name":"(\K[\w\d-]*)'
SERVICE_PORTS_REGEXP='"upnp.forward_ports":"(\K[\d\w]*)'

function log {
    echo " [INFO] "$1
}

function log_debug {
    if [[ ! -z ${DEBUG} ]]; then echo " [DEBUG] "$1; fi
}

if [[ -z ${DOCKER_SOCKET} ]]; then
    log "No Docker socket file defined! Please set the DOCKER_SOCKET variable to the host's docker.sock file bind mounted into the container."
    exit 1
fi
if [[ ! -S ${DOCKER_SOCKET} ]]; then
    log "Docker socket file ${DOCKER_SOCKET} does not exist! Please mount the host's docker.sock file into the container."
    exit 1
fi

while true; do
    if [[ -z ${IGD_DEVICE_URL} ]]; then
        log "Trying to find IGD device..."
        IGD_DEVICE_URL=$(upnpc -L | grep -Po ${IGD_DEVICE_REGEXP})
    fi
    if [[ -z ${IGD_DEVICE_URL} ]]; then
        log "Failed to find an IGD device on the network! Try specifying the URL using the IGD_DEVICE_URL environment variable."
        exit 1
    fi
    log_debug "Found IGD at ${IGD_DEVICE_URL}."

    log "Getting current UPNP port mappings from ${IGD_DEVICE_URL}..."
    current_forwards=$(upnpc -u ${IGD_DEVICE_URL} -L)

    log "Getting services with upnp_forward_ports label set..."
    service_specs=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/services" --data-urlencode 'filters={"label":{"upnp.forward_ports":true}}')
    services=$(echo ${service_specs} | grep -Po ${SERVICE_NAME_REGEXP})

    log_debug "Services: ${services}"

    if [[ ! -z ${services} ]]; then
        for service_name in $services; do

            log "Getting service spec for ${service_name}..."
            service_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/services" --data-urlencode 'filters={"name":{"'${service_name}'":true}}')
            log_debug "Service spec for ${service_name}: ${service_spec}"

            log "Getting port numbers for ${service_name}..."
            port_numbers=$(echo ${service_spec} | grep -Po ${SERVICE_PORTS_REGEXP})
            log_debug "Port numbers for ${service_name}: ${port_numbers}"

            log "Getting task spec for ${service_name}..."
            task_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/tasks" --data-urlencode 'filters={"service":{"'${service_name}'":true},"desired-state":{"running":true}}')
            log_debug "Task spec for ${service_name}: ${task_spec}"

            if [[ ! -z ${task_spec} ]]; then
                node_id=$(echo ${task_spec} | grep -Po ${NODEID_REGEXP})
                if [[ -z ${node_id} ]]; then
                    log "Failed to find node ID for ${service_name}!"
                    if [[ ! -z ${FAIL_ON_MISSING_SERVICE} ]]; then
                        exit 1
                    fi
                else
                    log "Service ${service_name} found on node ${node_id}."
                fi
            fi

            if [[ ! -z ${node_id} ]]; then
                node_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/nodes/${node_id}")
                log_debug "Node spec: $(echo ${node_spec})"

                for ip in $(echo ${node_spec} | grep -Po ${IPADDR_REGEXP}); do
                    if [[ ${ip} != "0.0.0.0" ]]; then
                        node_ip=${ip}
                    fi
                done
                if [[ -z ${node_ip} ]]; then
                    log "Failed to find IP address for node ${node_id}!"
                    if [[ ! -z ${FAIL_ON_MISSING_SERVICE} ]]; then
                        exit 1
                    fi
                else
                    log "IP address for ${node_id} is ${node_ip}."
                fi
            fi

            if [[ ! -z ${node_ip} ]]; then
                for port in ${port_numbers}; do
                    current_ip=$(echo ${current_forwards} | grep -Po ".*TCP\s+${port}->(\K[\d\.]+)")
                    if [[ -z ${current_ip} ]] || [[ ${node_ip} != ${current_ip} ]]; then
                        if [[ -z ${current_ip} ]]; then
                            log "Port ${port} not currently forwarded."
                        else
                            log "Port ${port} currently forwarded to ${current_ip}, removing..."
                            upnpc -u ${IGD_DEVICE_URL} -d ${port} TCP
                        fi
                        log "Forwarding port ${port} to ${node_ip}..."
                        upnpc -u ${IGD_DEVICE_URL} -a ${node_ip} ${port} ${port} TCP -e "Docker service ${service_name}"
                    else
                        log "Port ${port} correctly forwarded to ${node_ip}, nothing to do."
                    fi
                done
            fi
        done
    else
        log "No services found."
    fi

    log "Waiting ${UPDATE_FREQ} seconds to next update cycle..."
    sleep ${UPDATE_FREQ}
done