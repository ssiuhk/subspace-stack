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

/usr/local/bin/docker-compose up -d

PROJECT_NAME=$(basename `pwd`)
IFACE="br-$(docker network list | grep "${PROJECT_NAME}_default" | head -1 | awk '{print $1}')"

if command -v firewall-cmd > /dev/null 2>&1; then
    firewall-cmd --zone=trusted --add-interface ${IFACE}
    [ $? -eq 0 ] && echo "Added Interface ${IFACE} to Firewall zone 'trusted'"
    firewall-cmd --permanent --zone=trusted --add-interface ${IFACE}
fi
