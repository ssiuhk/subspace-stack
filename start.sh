#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "${SCRIPT_DIR}"

# 1. Check if .env file exists
if [ -e ${SCRIPT_DIR}/.env ]; then
    source ${SCRIPT_DIR}/.env
elif [ -s ${SCRIPT_DIR}/env.sample ]; then
    echo -n "Please input subspace http hostname: "; read SUBSPACE_HTTP_HOST
    SUBNET_2=$(shuf -i 0-253 -n 1)
    SUBNET_3=$(shuf -i 0-253 -n 1)
    IPV4_SUBNET="10.${SUBNET_2}.${SUBNET_3}"
    IPV6_SUBNET="fd00::${SUBNET_2}:${SUBNET_3}:"
    cp ${SCRIPT_DIR}/env.sample ${SCRIPT_DIR}/.env
    sed -i "s/SUBSPACE_HTTP_HOST.*/SUBSPACE_HTTP_HOST=${SUBSPACE_HTTP_HOST}/g" ${SCRIPT_DIR}/.env
    sed -i "s/SUBSPACE_IPV4_NETWORK.*/SUBSPACE_IPV4_NETWORK=\"${IPV4_SUBNET}\"/g" ${SCRIPT_DIR}/.env
    sed -i "s/SUBSPACE_IPV6_NETWORK.*/SUBSPACE_IPV6_NETWORK=\"${IPV6_SUBNET}\"/g" ${SCRIPT_DIR}/.env
    source ${SCRIPT_DIR}/.env
else
    echo "ERROR: Can't create .env file! env.sample does not exist!" >&2
    exit 1
fi

/usr/local/bin/docker-compose pull
[ $? -ne 0 ] && /usr/local/bin/docker-compose build # Only build if upstream image not available
/usr/local/bin/docker-compose up -d

PROJECT_NAME=$(basename `pwd`)
IFACE="br-$(docker network list | grep "${PROJECT_NAME}_default" | head -1 | awk '{print $1}')"

if command -v firewall-cmd > /dev/null 2>&1; then
    for INTERFACE in wg0 ${IFACE}; do
	if ! firewall-cmd --zone=trusted --query-interface=${INTERFACE} >/dev/null 2>&1; then
            firewall-cmd --zone=trusted --add-interface ${INTERFACE} >/dev/null 2>&1
            [ $? -eq 0 ] && echo "Added Interface ${INTERFACE} to Firewall zone 'trusted'"
            firewall-cmd --permanent --zone=trusted --add-interface ${INTERFACE} >/dev/null 2>&1
	fi
    done
    for port_proto in "${SUBSPACE_LISTENPORT}/udp" "${SUBSPACE_LISTENPORT}/tcp"; do
        if ! firewall-cmd --query-port="${port_proto}" >/dev/null 2>&1; then
            firewall-cmd --add-port "${port_proto}" >/dev/null 2>&1
            [ $? -eq 0 ] && echo "Added port "${port_proto}" to Firewall"
            firewall-cmd --permanent --add-port "${port_proto}" >/dev/null 2>&1
	fi
    done
    for service in http https; do
        if ! firewall-cmd --query-service=${service} > /dev/null 2>&1; then
            firewall-cmd --add-service ${service} >/dev/null 2>&1
            [ $? -eq 0 ] && echo "Added ${service} service to Firewall"
            firewall-cmd --permanent --add-service ${service} >/dev/null 2>&1
	fi
    done
fi
