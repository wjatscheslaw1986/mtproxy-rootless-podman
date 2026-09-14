#!/bin/bash

umask 077

read -r -s -p "Enter proxy user password (16 characters): " user_password
echo

password_length=${#user_password}

if [ ! ${password_length} -eq 16 ]; then
    echo "User password length must be exactly 16 characters of length"
    exit 1
fi

od -An -v -tx1 "$user_password" | tr -d ' \n' > mtproxy_user_pass

podman secret rm mtproxy-user-pass 2>/dev/null || true
podman secret create mtproxy-user-pass mtproxy_user_pass

shred mtproxy_user_pass && rm mtproxy_user_pass

user_password=
unset user_password

echo "Podman secret 'mtproxy-user-pass' has been created"

