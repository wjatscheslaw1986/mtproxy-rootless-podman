#!/bin/bash

USER_SECRET_FILE_PATH=/run/mtproxy/user-secret
PROXY_SECRET=/run/mtproxy/proxy-secret

die() {
    log "ERROR: $*"
    exit 1
}

read_secret() {
       local file="$1"

       require_file "$file"

       local value
       value="$(<"$file")"

       [[ -n "$value" ]] || die "Secret is empty: $file"

       printf '%s' "$value"
}

require_file() {
    local file="$1"

    [[ -f "$file" ]] || die "Required file does not exist: $file"
    [[ -r "$file" ]] || die "Required file is not readable: $file"
}

exec mtproto-proxy -u nobody -p 8888 -H 443 -S "$(read_secret "$USER_SECRET_FILE_PATH")" --aes-pwd "$PROXY_SECRET" /opt/mtproxy/proxy-multi.conf -M 1

