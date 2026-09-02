# mtproxy-rootless-podman

## Safe &amp; Secure MTProxy systemd Service Installer

### Overview

This project makes use of `make` utility to provide you with a convenient API.  
Here's the step-by-step guide to install the MTProto systemd service:  
- make sure the `/etc/sysctl.conf` lists the minimum unprivileged port which is not greater than `443`. If the line is missing, append it `echo 'net.ipv4.ip_unprivileged_port_start=443' | tee -a /etc/sysctl.conf`
- log in as a non-root user and make sure the `build-essential` package is available on your machine
- from inside the project directory, run `make` and enter the proxy user password. If you leave the password blank, then 'xxxyyyzzz' is going to be the proxy user password.
- Optional step: create and mount a working directory for the systemd service

