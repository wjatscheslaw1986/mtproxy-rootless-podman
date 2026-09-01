#!/bin/bash

BASE_DIR=${1:-"${HOME}"}

mkdir -p "${BASE_DIR}"/mtproxy && rm -rf "${BASE_DIR}"/mtproxy/* && curl -s https://core.telegram.org/getProxyConfig -o "${BASE_DIR}"/mtproxy/proxy-multi.conf
