#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "${SCRIPT_DIR}"

PROJECT_NAME=$(basename `pwd`)
IFACE="br-$(docker network list | grep "${PROJECT_NAME}_default" | head -1 | awk '{print $1}')"

if command -v firewall-cmd > /dev/null 2>&1; then
    firewall-cmd --zone=trusted --remove-interface ${IFACE}
    [ $? -eq 0 ] && echo "Removed Interface ${IFACE} to Firewall zone 'trusted'"
    firewall-cmd --permanent --zone=trusted --remove-interface ${IFACE}
fi
/usr/local/bin/docker-compose down
