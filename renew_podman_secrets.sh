#!/bin/bash

umask 077

read -r -s -p "Enter proxy user password: " user_password
echo

printf '%s' "$user_password" > mtproxy_user_pass

podman secret rm mtproxy-user-pass 2>/dev/null || true
podman secret create mtproxy-user-pass mtproxy_user_pass

shred mtproxy_user_pass && rm mtproxy_user_pass

user_password=
unset user_password

echo "Podman secret 'mtproxy-user-pass' has been created"

