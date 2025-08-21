# LXC Keepalive for Proxmox

This project provides a simple keepalive script and systemd service to monitor and automatically restart specified Proxmox LXC containers if they stop running.

## Features

- Monitors multiple LXC containers by their container IDs.
- Automatically restarts any container that is not running.
- Runs continuously as a systemd service on the Proxmox host.
- Supports starting, stopping, and showing status of monitored containers.

## Installation

1. Run the setup script as root:
```
sudo ./setup_lxc_keepalive.sh
```

2. The script installs the keepalive monitoring script and a systemd service.

3. The service starts automatically and monitors example containers: `101`, `102`, `103`.

## Usage

- To check the service status:

```
systemctl status lxc_keepalive.service
```
- To stop the service:
```
systemctl stop lxc_keepalive.service
```

- To change which containers are monitored:

1. Edit `/etc/systemd/system/lxc_keepalive.service` and modify the container IDs in the `ExecStart` line.
2. Reload systemd and restart the service:

   ```
   systemctl daemon-reload
   systemctl restart lxc_keepalive.service
   ```

## Script Commands

You can also run the keepalive script directly with:
```
/usr/local/bin/lxc_keepalive.sh start <LXC_IDs...>
/usr/local/bin/lxc_keepalive.sh stop
/usr/local/bin/lxc_keepalive.sh status
```

## Notes

- Ensure you run commands as `root` or with sufficient permissions to manage Proxmox containers.
- The keepalive script checks container status every 60 seconds.
- Logs are printed to the console via systemd journal (`journalctl -u lxc_keepalive.service`).
