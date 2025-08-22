Proxmox LXC Keepalive Service

You can download the keepalive script directly from GitHub:

- Using wget:
```
wget https://raw.githubusercontent.com/your-user/your-repo/main/lxc_keepalive.sh -O /usr/local/bin/lxc_keepalive.sh
chmod +x /usr/local/bin/lxc_keepalive.sh
```
- Using curl:
```
curl -o /usr/local/bin/lxc_keepalive.sh https://raw.githubusercontent.com/your-user/your-repo/main/lxc_keepalive.sh
chmod +x /usr/local/bin/lxc_keepalive.sh
```
- Or clone the entire repository:
```
git clone https://github.com/your-user/your-repo.git
cd your-repo
```
### Copy or move lxc_keepalive.sh to /usr/local/bin
```
cp lxc_keepalive.sh /usr/local/bin/
chmod +x /usr/local/bin/lxc_keepalive.sh
```
---

## Features

- Continuously monitors specified Proxmox LXC containers.
- Automatically starts containers that are stopped.
- Configurable list of monitored containers via a simple config file.
- Managed as a systemd service for automatic background operation.
- Supports start, stop, and status commands.

---

## Installation

1. Run the provided setup script to install the keepalive script, create the config file, and enable the systemd service:
```
sudo ./setup_lxc_keepalive.sh
```
You will be prompted to enter the container IDs to monitor (space-separated).

---

## Configuration

- Container IDs to monitor are stored in:
```
/etc/lxc_keepalive/lxc_keepalive.conf
```
- List container IDs separated by spaces on a single line. Example:
```
111 112 113
```
---

## Managing the Service

Start monitoring
```
sudo systemctl start lxc_keepalive.service
```
Stop monitoring
```
sudo systemctl stop lxc_keepalive.service
```
Restart service (e.g., after modifying config)
```
sudo systemctl restart lxc_keepalive.service
```
Enable service to start at boot
```
sudo systemctl enable lxc_keepalive.service
```
Disable automatic start at boot
```
sudo systemctl disable lxc_keepalive.service
```
Check service status
```
sudo systemctl status lxc_keepalive.service
```
View live service logs
```
sudo journalctl -u lxc_keepalive.service -f
```
---

## Modify monitored containers

1. Edit the config file with your desired container IDs:
```
sudo nano /etc/lxc_keepalive/lxc_keepalive.conf
```
2. Restart the service to apply updates:
```
sudo systemctl restart lxc_keepalive.service
```
---

## Manual script usage

You can run the script manually for debugging:
```
sudo /usr/local/bin/lxc_keepalive.sh start   # starts monitoring (requires config file)
sudo /usr/local/bin/lxc_keepalive.sh stop    # stops monitoring process (if running)
sudo /usr/local/bin/lxc_keepalive.sh status  # shows currently monitored containers
```
---

## Notes

- The service runs continuously in the background and automatically restarts if it crashes.
- The script requires root privileges to manage LXC containers.
- Logs are sent to syslog and can be accessed via journalctl as shown above.

---

## Troubleshooting

- If the service fails to start, check logs:
```
sudo journalctl -u lxc_keepalive.service -b
```
- Ensure the container IDs in the config file are valid and exist.
- Verify /usr/local/bin/lxc_keepalive.sh is executable.

---

This keeps your specified Proxmox LXC containers running without manual intervention.
