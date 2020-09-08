FROM alpine:latest

RUN apk add --no-cache dnscrypt-proxy drill && \
    sed -i "s#listen_addresses =.*#listen_addresses = ['0.0.0.0:5053', '[::/0]:5053']#g" /etc/dnscrypt-proxy/dnscrypt-proxy.toml

USER dnscrypt

EXPOSE 5053/tcp 5053/udp

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT /entrypoint.sh

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s \
    CMD drill -p 5053 www.google.com @127.0.0.1 || exit 1

