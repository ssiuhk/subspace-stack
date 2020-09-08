#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "${SCRIPT_DIR}"

PROJECT_NAME=$(basename `pwd`)
IFACE="br-$(docker network list | grep "${PROJECT_NAME}_default" | head -1 | awk '{print $1}')"

if command -v firewall-cmd > /dev/null 2>&1; then
    for INTERFACE in wg0 ${IFACE}; do
	if firewall-cmd --zone=trusted --query-interface=${INTERFACE} >/dev/null 2>&1; then
            firewall-cmd --zone=trusted --remove-interface ${INTERFACE} >/dev/null 2>&1
            [ $? -eq 0 ] && echo "Removed Interface ${INTERFACE} to Firewall zone 'trusted'"
            firewall-cmd --permanent --zone=trusted --remove-interface ${INTERFACE} >/dev/null 2>&1
	fi
    done
    for port_proto in "${SUBSPACE_LISTENPORT}/udp" "${SUBSPACE_LISTENPORT}/tcp"; do
        if firewall-cmd --query-port "${port_proto}" >/dev/null 2>&1; then
	    firewall-cmd --remove--port "${port_proto}" >/dev/null 2>&1
	    [ $? -eq 0 ] && echo "Removed port ${port_proto} from Firewall"
	    firewall-cmd --permanent --remove--port "${port_proto}" >/dev/null 2>&1
	fi
    done
    for service in http https; do
        if firewall-cmd --query-service ${service} >/dev/null 2>&1; then
            firewall-cmd --delete-service ${service} >/dev/null 2>&1
            [ $? -eq 0 ] && echo "Deleted ${service} service from Firewall"
            firewall-cmd --permanent --delete-service ${service} >/dev/null 2>&1
        fi
    done
fi
/usr/local/bin/docker-compose down
