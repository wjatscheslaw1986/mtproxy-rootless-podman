FROM docker.io/library/debian:trixie-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/MTProxy/objs/bin:${PATH}"

ARG COMMIT_HASH="f36d8af769ffaeac36978d38c2c0f6d1104c2137"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git curl build-essential libssl-dev zlib1g-dev; \
    rm -rf /var/lib/apt/lists/*; \
    git clone https://github.com/TelegramMessenger/MTProxy /MTProxy && \
    cd MTProxy && git checkout $COMMIT_HASH && make && mkdir -p /opt/MTProxy;

COPY --chmod=0544 entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
