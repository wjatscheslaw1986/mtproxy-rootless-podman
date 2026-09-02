#!/usr/bin/env bash

set -eu

# check a user isn't root
if [ "$(id -u)" = 0 ]; then
  echo "Please, don't run this script as root"
  exit 1
fi

SERVICE_NAME=${1}
IMAGE=${2}
SUBUID_BLOCK_INDEX=${3}
LOG_LEVEL=${4:-warn}
BASE_DIR=${5:-"${HOME}"}
readonly BLOCK_SIZE=65536
USE_WORKING_DIR=${6:-0}

if [ -z "${SUBUID_BLOCK_INDEX}" ]; then
    echo "SUBUID_BLOCK_INDEX isn't set, but required."
    exit 1
fi

[[ "$SUBUID_BLOCK_INDEX" =~ ^[0-9]+$ ]] ||
    {
        echo "SUBUID_BLOCK_INDEX must be a non-negative integer" >&2
        exit 1
    }

HOST_UID_BASE=$((SUBUID_BLOCK_INDEX * BLOCK_SIZE))

LAST_UID=$((HOST_UID_BASE + BLOCK_SIZE - 1))

(( LAST_UID <= 512 * BLOCK_SIZE - 1 )) ||
    {
        echo "Requested block exceeds allocated subuid range." >&2
        exit 1
    }

UIDMAP=(
    --uidmap=0:$((HOST_UID_BASE + 1)):"${BLOCK_SIZE}"
)

GIDMAP=(
    --gidmap=0:$((HOST_UID_BASE + 1)):"${BLOCK_SIZE}"
)

WORKING_DIRECTORY=(
    -v ${BASE_DIR}/.config/MTProxy:/opt/MTProxy:rw
)

if [ $((USE_WORKING_DIR)) == 0 ]; then
    WORKING_DIRECTORY=()
fi

if [ -z "${SERVICE_NAME}" ]; then
    echo "Install autoload: service name isn't set, but required."
    exit 1
fi

if [ -z "${IMAGE}" ]; then
    echo "Install autoload: image name isn't set, but required."
    exit 1
fi


echo "Variable values:"
echo "IMAGE=$IMAGE"
echo "SERVICE_NAME=$SERVICE_NAME"
echo "HOST_UID_BASE=$HOST_UID_BASE"
echo "LAST_UID=$LAST_UID"
echo "UIDMAP=$UIDMAP"
echo "GIDMAP=$GIDMAP"

podman image exists "$IMAGE" ||
    {
        echo "Image not found: $IMAGE" >&2
        exit 1
    }

# Replace the shell with Podman so signals propagate directly, using 'exec':
exec podman run \
       --log-level="${LOG_LEVEL}" \
       --log-driver=journald \
       --rm \
       --read-only \
       --security-opt=no-new-privileges \
       --cap-drop=ALL \
       --cap-add=SETUID \
       --cap-add=SETGID \
       --cap-add=NET_BIND_SERVICE \
       "${UIDMAP[@]}" \
       "${GIDMAP[@]}" \
       --secret source=mtproxy-user-pass,type=mount,uid=0,gid=0,mode=0400,target=mtproxy-user-pass \
       -p 443:443/tcp \
       -p 443:443/udp \
       --name "$SERVICE_NAME" \
       "${WORKING_DIRECTORY}" \
       --tmpfs /tmp:rw,noexec,nosuid,size=64m \
       --tmpfs /run:rw,noexec,nosuid,size=16m \
       --tmpfs /var/run,rw,noexec,nosuid,size=16m \
      "$IMAGE"

