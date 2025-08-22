#!/bin/bash

# Setup variables
CONFIG_DIR="/etc/lxc_keepalive"
CONFIG_FILE="$CONFIG_DIR/lxc_keepalive.conf"
SCRIPT_PATH="/usr/local/bin/lxc_keepalive.sh"
SERVICE_PATH="/etc/systemd/system/lxc_keepalive.service"

# Prompt user for container IDs
echo "Enter the LXC container IDs to keep alive (space separated):"
read -r CONTAINER_IDS

# Create config directory and file
mkdir -p "$CONFIG_DIR"
echo "$CONTAINER_IDS" > "$CONFIG_FILE"
echo "Config file created at $CONFIG_FILE with container IDs: $CONTAINER_IDS"

# Create the keepalive script
cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash

CONFIGFILE="/etc/lxc_keepalive/lxc_keepalive.conf"
PIDFILE="/etc/lxc_keepalive/lxc_keepalive.pid"

function start_monitoring() {
  if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "Keepalive is already running with PID $(cat "$PIDFILE")"
    exit 1
  fi

  if [ ! -f "$CONFIGFILE" ]; then
    echo "Configuration file $CONFIGFILE not found!"
    exit 1
  fi

  read -r -a LXC_LIST < "$CONFIGFILE"
  if [ ${#LXC_LIST[@]} -eq 0 ]; then
    echo "No container IDs found in $CONFIGFILE"
    exit 1
  fi

  echo $$ > "$PIDFILE"
  echo "Keepalive started with PID $$"
  echo "Monitoring containers: ${LXC_LIST[@]}"

  while true; do
    for LXC_ID in "${LXC_LIST[@]}"; do
      STATUS=$(pct status "$LXC_ID" 2>/dev/null | grep status | awk '{print $2}')
      if [ "$STATUS" != "running" ]; then
        echo "$(date): Container $LXC_ID is not running. Starting it..."
        pct start "$LXC_ID"
      else
        echo "$(date): Container $LXC_ID is running fine."
      fi
    done
    sleep 60
  done
}

function stop_monitoring() {
  if [ ! -f "$PIDFILE" ]; then
    echo "No keepalive process found."
    exit 1
  fi

  PID=$(cat "$PIDFILE")
  if kill -0 $PID 2>/dev/null; then
    kill $PID
    rm -f "$PIDFILE"
    echo "Keepalive stopped."
  else
    echo "Process $PID not running. Removing stale PID file."
    rm -f "$PIDFILE"
  fi
}

function show_status() {
  if [ ! -f "$CONFIGFILE" ]; then
    echo "Configuration file not found at $CONFIGFILE"
    exit 1
  fi

  echo "Currently monitored containers (from $CONFIGFILE):"
  cat "$CONFIGFILE"
}

case "$1" in
  start)
    start_monitoring
    ;;
  stop)
    stop_monitoring
    ;;
  status)
    show_status
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    echo "Monitored containers read from $CONFIGFILE"
    exit 1
    ;;
esac
EOF

chmod +x "$SCRIPT_PATH"
echo "Keepalive script installed at $SCRIPT_PATH and made executable."

# Create the systemd service file
cat > "$SERVICE_PATH" << EOF
[Unit]
Description=Proxmox LXC Keepalive Service
After=network.target

[Service]
Type=simple
ExecStart=$SCRIPT_PATH start
ExecStop=$SCRIPT_PATH stop
Restart=always
RestartSec=10
User=root
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=lxc_keepalive

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service file created at $SERVICE_PATH."

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable lxc_keepalive.service
systemctl start lxc_keepalive.service

echo "Service lxc_keepalive started and enabled on boot."
echo "Use 'systemctl status lxc_keepalive' and 'journalctl -u lxc_keepalive -f' for logs and status."
