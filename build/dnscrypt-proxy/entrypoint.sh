#!/bin/sh

set -ex

if [ "$#" -eq 0 ]; then

	/usr/bin/dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml

else
        "$@"
fi

