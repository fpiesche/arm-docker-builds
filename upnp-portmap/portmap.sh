#!/bin/bash

NODEID_REGEXP='NodeID"\:"(\K\w+)'
IPADDR_REGEXP='\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
IGD_DEVICE_REGEXP="(\Khttp.*.xml)"
SERVICE_NAME_REGEXP='"Spec":{"Name":"(\K[\w\d-]*)'
SERVICE_PORTS_REGEXP='"upnp.forward_ports":"(\K[\d\w\s]*)'

function log {
    echo " [INFO] "$1
}

function log_debug {
    if [[ ! -z ${DEBUG} ]]; then echo " [DEBUG] "$1; fi
}

function check_upnpc_status {
    if [[ $1 != 0 ]]; then echo " [ERROR] Failed to run upnpc command: $2"; fi
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

    log "Getting current UPNP port mappings from ${IGD_DEVICE_URL}..."
    current_forwards=$(upnpc -u ${IGD_DEVICE_URL} -L)

    log "Getting services with upnp.forward_ports label..."
    service_specs=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/services" --data-urlencode 'filters={"label":{"upnp.forward_ports":true}}')
    services=$(echo ${service_specs} | grep -Po ${SERVICE_NAME_REGEXP})

    log "Found: ${services}"

    if [[ ! -z ${services} ]]; then
        for service_name in $services; do

            log "${service_name}: Getting service spec..."
            service_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/services" --data-urlencode 'filters={"name":{"'${service_name}'":true}}')
            log_debug "${service_spec}"

            log "${service_name}: Getting task spec..."
            task_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/tasks" --data-urlencode 'filters={"service":{"'${service_name}'":true},"desired-state":{"running":true}}')
            log_debug "${task_spec}"

            if [[ ! -z ${task_spec} ]]; then
                log "${service_name}: Getting node ID..."
                node_id=$(echo ${task_spec} | grep -Po ${NODEID_REGEXP})
                if [[ -z ${node_id} ]]; then
                    log "${service_name}: Failed to find node ID!"
                    if [[ ! -z ${FAIL_ON_MISSING_SERVICE} ]]; then
                        exit 1
                    fi
                else
                    log "${service_name}: Found on node ${node_id}."
                fi
            fi

            if [[ ! -z ${node_id} ]]; then
                log "${service_name}: Getting node spec..."
                node_spec=$(curl -s --unix-socket ${DOCKER_SOCKET} -gG -XGET "v132/nodes/${node_id}")
                log_debug "${node_spec}"

                for ip in $(echo ${node_spec} | grep -Po ${IPADDR_REGEXP}); do
                    if [[ ${ip} != "0.0.0.0" ]]; then
                        node_ip=${ip}
                    fi
                done
                if [[ -z ${node_ip} ]]; then
                    log "${service_name}: Failed to find IP address for node ${node_id}!"
                    if [[ ! -z ${FAIL_ON_MISSING_SERVICE} ]]; then
                        exit 1
                    fi
                else
                    log "${service_name}: IP address for ${node_id} is ${node_ip}."
                fi
            fi

            if [[ ! -z ${node_ip} ]]; then

                log "${service_name}: Getting internal port numbers to forward..."
                internal_ports=$(echo ${service_spec} | grep -Po ${SERVICE_PORTS_REGEXP} | uniq )
                log "${service_name}: Internal ports to forward: ${internal_ports}"

                for port in ${internal_ports}; do
                    external_port=$(echo ${service_spec} | grep -Po -m 1 '"TargetPort":'${port}',"PublishedPort":(\K\d*)' | tail -1)
                    if [[ -z ${external_port} ]]; then
                        log "${service_name}: Internal port ${port} is not exposed on container - not forwarding."
                    else
                        log "${service_name}: Internal port ${port} is exposed as ${external_port}."
                        current_ip=$(echo ${current_forwards} | grep -Po ".*TCP\s+${port}->(\K[\d\.]+)")
                        if [[ -z ${current_ip} ]] || [[ ${node_ip} != ${current_ip} ]]; then
                            if [[ -z ${current_ip} ]]; then
                                log "${service_name}: Port ${external_port} not currently forwarded."
                            else
                                log "${service_name}: Port ${external_port} currently forwarded to ${current_ip}, removing..."
                                upnpc_output=$(upnpc -u ${IGD_DEVICE_URL} -d ${external_port} TCP)
                                check_upnpc_status $? $upnpc_output
                            fi
                            log "${service_name}: Forwarding port ${external_port} to ${node_ip}..."
                            upnpc_output=$(upnpc -e "Docker ${service_name}" -u ${IGD_DEVICE_URL} -a ${node_ip} ${external_port} ${external_port} TCP 0 "")
                            check_upnpc_status $? $upnpc_output
                            upnpc_output=$(upnpc -e "Docker ${service_name}" -u ${IGD_DEVICE_URL} -a ${node_ip} ${external_port} ${external_port} UDP 0 "")
                            check_upnpc_status $? $upnpc_output
                        else
                            log "${service_name}: Port ${external_port} correctly forwarded to ${node_ip}, nothing to do."
                        fi
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