#!/bin/bash

readonly USER_SECRET_FILE_PATH=/run/secrets/mtproxy-user-pass
readonly PROXY_SECRET=/run/mtproxy-pass
readonly PROXY_CONFIG=/run/proxy-multi.conf
readonly DEFAULT_USER_PASSWORD=xxxyyyzzz

read_secret() {
    local file="$1"
    local value

    if [ \( ! -f "$file" \) -o \( ! -r "$file" \) ]
    then value="$DEFAULT_USER_PASSWORD"
    fi

    if [ -n "$value" ]
    then value="$(<"$file")"
    fi

    [[ -n "$value" ]] || value="$DEFAULT_USER_PASSWORD"

    printf '%s' "$value"
}

#Download Telegram server secret
curl --fail --silent --show-error --location --retry 5 --retry-all-errors https://core.telegram.org/getProxySecret -o "$PROXY_SECRET" && chmod 0400 "$PROXY_SECRET"

#Download Telegram server config
curl --fail --silent --show-error --location --retry 5 --retry-all-errors https://core.telegram.org/getProxyConfig -o "$PROXY_CONFIG" && chmod 0400 "$PROXY_CONFIG"

exec mtproto-proxy -u nobody -p 8888 -H 443 -S "$(read_secret "$USER_SECRET_FILE_PATH")" --aes-pwd "$PROXY_SECRET" /opt/MTProxy/proxy-multi.conf -M 1

