#!/bin/bash

set -eu

readonly USER_SECRET_FILE_PATH=/run/secrets/mtproxy-user-pass
readonly PROXY_SECRET=/run/mtproxy-pass
readonly PROXY_CONFIG=/run/proxy-multi.conf
readonly DEFAULT_USER_PASSWORD=61616161616161616161616161616161

read_secret() {
    local file="$1"
    local value=""

    if [ \( ! -f "$file" \) -o \( ! -r "$file" \) ]
        then echo "ERROR: secret file is missing of unreadable: $file" >&2
        exit 1
    fi

    value="$(<"$file")"

    if [[ ! "$value" =~ ^[0-9a-fA-F]{32}$ ]]; then
        echo "WARNING: invalid MTProxy secret: expected 32 hex digits. Fallback to a default password"
        value="$DEFAULT_USER_PASSWORD"
    fi

    printf '%s' "$value"
}

#Download Telegram server secret
rm -f "$PROXY_SECRET" && curl --fail --silent --show-error --location --retry 5 --retry-all-errors https://core.telegram.org/getProxySecret -o "$PROXY_SECRET" && chmod 0400 "$PROXY_SECRET"

#Download Telegram server config
rm -f "$PROXY_CONFIG" && curl --fail --silent --show-error --location --retry 5 --retry-all-errors https://core.telegram.org/getProxyConfig -o "$PROXY_CONFIG" && chmod 0400 "$PROXY_CONFIG"

exec mtproto-proxy -u nobody -p 8888 -H 9111 -S $(read_secret "$USER_SECRET_FILE_PATH") --aes-pwd "$PROXY_SECRET" "$PROXY_CONFIG" -M 1

