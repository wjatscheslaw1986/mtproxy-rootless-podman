# mtproxy-rootless-podman

## Safe and secure MTProxy systemd service installer

This project builds an MTProxy container image and runs it with rootless Podman. The container uses a dedicated subordinate UID/GID block instead of mapping the host user's UID directly into the container.

The project uses `make` as a small command-line interface for building the image, creating the Podman secret, and installing a user-level systemd service.

## Requirements

- A Linux host with Podman configured for rootless containers.
- A non-root user with entries in `/etc/subuid` and `/etc/subgid`.
- GNU `make`.
- A user systemd session. The installer enables lingering so the service can continue running without an interactive login.
- The host must allow rootless processes to bind to port 443. The examples below configure this with `net.ipv4.ip_unprivileged_port_start=443`.

The default `SUBUID_BLOCK_INDEX` is `3` and each block contains 65,536 IDs. With that default, Podman needs at least 262,144 subordinate UIDs and GIDs available to the user so that the fourth block can be mapped.

## Installation

### 1. Allow rootless binding to port 443

Create a persistent sysctl configuration and apply it:

```sh
printf '%s\n' 'net.ipv4.ip_unprivileged_port_start=443' | sudo tee /etc/sysctl.d/99-mtproxy-rootless.conf
sudo sysctl --system
```

### 2. Install and run the service

Assuming you Run the following command as the regular, non-root user from the project directory:

```sh
make
systemctl --user restart podman-mtproxy-1.service
```

This does:

1. Creates or replaces the Podman secret `mtproxy-user-pass`.
2. Installs and enables a user-level systemd service for the container, with lingering.
3. Starts the service

When prompted for the proxy client password, enter a password between 6 and 128 characters, or leave it blank for the default client password `xxxyyyzzz`. The secret is safely stored in Podman's secret store rather than in the image or the systemd unit.

### 3. Check the service

```sh
systemctl --user status podman-mtproxy-1.service
podman ps
```

The default container name is `mtproxy-1`.

## Configuration

The main values used by the installer are defined in the `Makefile`:

- `IMAGE`: local image name; defaults to `mtproxy`.
- `INSTANCE_ID`: instance number; defaults to `1`.
- `SUBUID_BLOCK_INDEX`: subordinate UID/GID block used by the container; defaults to `3`.
- `BASE_DIR`: base directory for optional persistent MTProxy files; defaults to the user's home directory.

You can override these variables when invoking `make`, for example:

```sh
make INSTANCE_ID=2 SUBUID_BLOCK_INDEX=4
```

The generated systemd unit runs under the user account and starts the container through the generated `${HOME}/.local/bin/mtproxy-1_run.sh` wrapper.

## Password rotation

To replace the proxy client password:

```sh
./renew_podman_secrets.sh
```

Assuming you haven't override the INSTANCE_ID during `make`, restart the service after changing the secret:

```sh
systemctl --user restart podman-mtproxy-1.service
```

## Rootless UID/GID isolation

The container is started with an explicit UID/GID mapping. Each instance can be assigned a different 65,536-ID block by changing `SUBUID_BLOCK_INDEX`.

The mapping is intentionally based on subordinate IDs rather than the host user's own UID/GID. This keeps the container's root user inside the user namespace from being mapped directly to the host account.

Make sure the selected block is actually available in the user's `/etc/subuid` and `/etc/subgid` configuration. The installer currently checks only the supported block-number range; it does not verify the host's complete subordinate-ID allocation.

## Container security settings

The runtime configuration currently uses several hardening options:

- `--read-only` for the container root filesystem.
- `--security-opt=no-new-privileges`.
- All Linux capabilities dropped, with only `SETUID`, `SETGID`, and `NET_BIND_SERVICE` added back.
- Temporary writable filesystems for `/tmp`, `/run`, and `/var/run`.
- The proxy password is supplied through a Podman secret rather than an environment variable or command-line argument.

MTProxy also downloads the Telegram proxy secret and proxy configuration when the container starts. It is recommended that you create a daily cron job restarting this systemd service, to make sure the configuration is up to date.

## Publishing container images

The GitHub Actions workflow is intended to publish release images to GitHub Container Registry and Docker Hub when a version tag is pushed.

Use Semantic Versioning for release tags, with a leading `v`, for example:

```text
v1.0.0
v1.2.3
v2.0.0-rc.1
```

For a normal release, create and push the tag with:

```sh
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
```

The Docker metadata configuration uses the semantic version from the Git tag as the image version (for example, `v1.2.3` becomes `1.2.3`) and automatically generates `latest` for stable semantic-version tags.

The release workflow should keep registry publishing conditional on a version-tag push. Pull requests and ordinary branch commits should not publish images.

## Debugging

If you are debugging this project, it is likely that you often call the following sequence of commands to rebuild the project and to see how is it working now:

```sh
make clean
make build
make debug
```

**Beware**: the `clean` goal of `make` also disables the systemd service, but does not remove it. You will likely want to re-enable it with `make autoload` after you're done with debugging.

## Project layout

- `Containerfile` — builds the MTProxy image.
- `entrypoint.sh` — obtains the Telegram proxy configuration and starts `mtproto-proxy`.
- `mtproxy_run.sh` — runs the container with the selected UID/GID mapping and security options.
- `install_autoload.sh` — installs the user-level systemd unit.
- `renew_podman_secrets.sh` — creates or replaces the Podman client-password secret.
- `Makefile` — provides the API to a developer of the project.
- `.github/workflows/docker-image-publish.yml` — builds and publishes release images.

