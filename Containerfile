FROM docker.io/library/debian:13.1-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git curl build-essential libssl-dev zlib1g-dev; \
    rm -rf /var/lib/apt/lists/*; \
    git clone https://github.com/TelegramMessenger/MTProxy && \
    mkdir -p /opt/mtproxy; \
    curl -s https://core.telegram.org/getProxyConfig -o /opt/mtproxy/proxy-multi.conf && \
    chmod 0444 /opt/mtproxy/proxy-multi.conf; \
    cd MTProxy && make && cd objs/bin

COPY --chmod=0544 entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
