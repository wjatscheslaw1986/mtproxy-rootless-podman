#!/bin/bash

USER_SECRET_FILE_PATH=/run/secrets/mtproxy-user-pass
PROXY_SECRET=/run/secrets/mtproxy-pass

die() {
    log "ERROR: $*"
    exit 1
}

require_file() {
    local file="$1"

    [[ -f "$file" ]] || die "Required file does not exist: $file"
    [[ -r "$file" ]] || die "Required file is not readable: $file"
}

read_secret() {
       local file="$1"

       require_file "$file"

       local value
       value="$(<"$file")"

       [[ -n "$value" ]] || die "Secret is empty: $file"

       printf '%s' "$value"
}

#Download Telegram server secret
curl -s https://core.telegram.org/getProxySecret -o "$PROXY_SECRET" && chmod 0400 "$PROXY_SECRET"

#Download Telegram server config
curl -s https://core.telegram.org/getProxyConfig -o /opt/MTProxy/proxy-multi.conf && chmod 0400 /opt/MTProxy/proxy-multi.conf

exec mtproto-proxy -u nobody -p 8888 -H 443 -S "$(read_secret "$USER_SECRET_FILE_PATH")" --aes-pwd "$PROXY_SECRET" /opt/MTProxy/proxy-multi.conf -M 1

