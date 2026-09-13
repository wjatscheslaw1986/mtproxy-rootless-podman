#!/bin/bash

if [ "$(id -u)" = 0 ]; then
  echo "Please, don't run this script as root"
  exit 1
fi

IMAGE=${1}
ORDINAL=${2:-1}
SERVICE_NAME=mtproxy-${ORDINAL}
SUBUID_BLOCK_INDEX=${3:-0}
BASE_DIR=${4:-"${HOME}"}
LOG_LEVEL=${5:-warn}
TEMPLATE_FILE=mtproxy_run.sh

if [[ ! "$ORDINAL" =~ ^[0-9]+$ ]] || (( ORDINAL <= 0 )); then
    echo "Install autoload: instance ordinal must be a positive integer."
    exit 1
fi

if [ -z "${IMAGE}" ]; then
    echo "Install autoload: image name isn't set, but required."
    exit 1
fi

SERVICE_PATH=$HOME/.config/systemd/user/podman-$SERVICE_NAME.service

mkdir -p "$HOME/.config/systemd/user" "$HOME/.local/bin"

cat > "$SERVICE_PATH" << EOF
[Unit]
Description=Safe & Secure MTProxy Service ($SERVICE_NAME)
After=network.target

[Service]
Type=simple
#WorkingDirectory=$HOME/.config/MTProxy
ExecStart=$HOME/.local/bin/${SERVICE_NAME}_run.sh $SERVICE_NAME $IMAGE $SUBUID_BLOCK_INDEX $LOG_LEVEL $BASE_DIR
#ExecStartPost=
ExecStop=/usr/bin/podman stop --ignore $SERVICE_NAME
ExecStopPost=/usr/bin/podman rm --force --ignore $SERVICE_NAME
Restart=on-failure
TimeoutStartSec=100
TimeoutStopSec=20
RestartSec=3

[Install]
WantedBy=default.target
EOF

cp "$TEMPLATE_FILE" $HOME/.local/bin/"$SERVICE_NAME"_run.sh && chmod 744 $HOME/.local/bin/"$SERVICE_NAME"_run.sh

systemctl --user daemon-reload
systemctl --user enable podman-$SERVICE_NAME.service
loginctl enable-linger $(whoami) || true
