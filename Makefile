SHELL := /bin/bash

.DEFAULT_GOAL := all

IMAGE := mtproxy

INSTANCE_ID := 1
CONTAINER := $(IMAGE)-$(INSTANCE_ID)

BASE_DIR := $(HOME)

SYSTEMD_SERVICE_FILE := mtproxy_run.sh

BLOCK_SIZE := 65536
SUBUID_BLOCK_INDEX := 3
INTERMEDIATE_UID_OFFSET := $(shell echo $$(( $(SUBUID_BLOCK_INDEX) * $(BLOCK_SIZE) + 1 )))


.PHONY: all build secrets debug config autoload stop down clean


all: build secrets autoload


build:
	@echo "Build MTProxy image"
	podman build \
		--tag $(IMAGE) \
		--file Containerfile
		.


secrets:
	@echo "Create/update secrets."
	./renew_podman_secrets.sh


debug:
	@echo "Running $(CONTAINER) container"
	
	podman run \
		--log-level=debug \
		--log-driver=journald \
		--rm -it \
		--read-only \
		--security-opt=no-new-privileges \
		--cap-drop=ALL \
		--cap-add=NET_BIND_SERVICE \
		--cap-add=SETUID \
		--cap-add=SETGID \
		--uidmap=0:$(INTERMEDIATE_UID_OFFSET):$(BLOCK_SIZE) \
		--gidmap=0:$(INTERMEDIATE_UID_OFFSET):$(BLOCK_SIZE) \
		--secret source=mtproxy-user-pass,type=mount,uid=0,gid=0,mode=0400,target=mtproxy-user-pass \
		--name "$(CONTAINER)" \
		-p 443:443/tcp \
		-p 443:443/udp \
		--tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m \
		--tmpfs /run:rw,noexec,nosuid,nodev,size=16m \
		--tmpfs /var/run:rw,noexec,nosuid,nodev,size=16m \
		localhost/"$(IMAGE)"


autoload:
	@echo "Installing user's systemd services for autoload..."
	
	@test -f "$(SYSTEMD_SERVICE_FILE)" || \
		{ echo "ERROR: missing $(SYSTEMD_SERVICE_FILE)" >&2; exit 1; }
	
	@./install_autoload.sh localhost/"$(IMAGE)" "$(INSTANCE_ID)" "$(SUBUID_BLOCK_INDEX)" "$(BASE_DIR)" warn
	
	@echo "Done."


stop:
	@echo 'Stop the systemd service and the container'
	-systemctl --user stop podman-$(CONTAINER).service
	-podman container stop "$(CONTAINER)"


down: stop
	@echo 'Disable the systemd service and remove the container'
	-systemctl --user disable podman-$(CONTAINER).service podman-$(CONTAINER).service
	-podman container rm "$(CONTAINER)"


clean: down
	@echo 'Remove the image and podman secrets'
	-podman rmi "$(IMAGE)"
	-podman secret rm mtproxy-pass
	-podman secret rm mtproxy-user-pass

