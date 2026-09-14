#!/bin/bash

set -eu
umask 077

read -r -s -p "Enter proxy user password (16 characters): " user_password
printf '\n'

password_length=${#user_password}

if [[ ! "$user_password" =~  ^[a-zA-Z0-9!@#%+=_,.:/-]{16}$ ]]; then
    printf '%s\n' "Password must contain exactly 16 printable ASCII characters" >&2
    exit 1
fi

podman secret rm mtproxy-user-pass 2>/dev/null || true
printf '%s' "$user_password" | od -An -v -tx1 | tr -d ' \n' | podman secret create mtproxy-user-pass -

unset user_password

printf '%s\n' "Podman secret 'mtproxy-user-pass' has been created"

