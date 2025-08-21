#!/bin/bash

# Setup LXC Keepalive script and systemd service

KEEPALIVE_PATH="/usr/local/bin/lxc_keepalive.sh"
SERVICE_PATH="/etc/systemd/system/lxc_keepalive.service"

echo "Creating keepalive script at $KEEPALIVE_PATH..."

cat > "$KEEPALIVE_PATH" << 'EOF'
#!/bin/bash

PIDFILE="/etc/lxc_keepalive/lxc_keepalive.pid"
LXCFILE="/etc/lxc_keepalive/lxc_keepalive.list"

function start_monitoring() {
  if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
    echo "Keepalive is already running with PID $(cat "$PIDFILE")"
    exit 1
  fi

  if [ "$#" -lt 2 ]; then
    echo "Usage: $0 start <LXC_ID1> <LXC_ID2> ..."
    exit 1
  fi

  LXC_LIST=("${@:2}")
  mkdir -p /etc/lxc_keepalive
  echo "${LXC_LIST[@]}" > "$LXCFILE"

  ( 
    while true; do
      for LXC_ID in "${LXC_LIST[@]}"; do
        STATUS=$(pct status $LXC_ID 2>/dev/null | grep status | awk '\''{print $2}'\'')
        if [ "$STATUS" != "running" ]; then
          echo "$(date): Container $LXC_ID is not running. Starting it..."
          pct start $LXC_ID
        else
          echo "$(date): Container $LXC_ID is running fine."
        fi
      done
      sleep 60
    done
  ) &

  echo $! > "$PIDFILE"
  echo "Keepalive started with PID $(cat $PIDFILE)"
  echo "Monitoring containers: ${LXC_LIST[@]}"
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
    rm -f "$LXCFILE"
    echo "Keepalive stopped."
  else
    echo "Process $PID not running. Removing stale PID and container list files."
    rm -f "$PIDFILE" "$LXCFILE"
  fi
}

function show_status() {
  if [ ! -f "$LXCFILE" ]; then
    echo "No containers are currently being kept alive."
    exit 0
  fi

  echo "Containers currently being kept alive:"
  cat "$LXCFILE"
}

case "$1" in
  start)
    start_monitoring "$@"
    ;;
  stop)
    stop_monitoring
    ;;
  status)
    show_status
    ;;
  *)
    echo "Usage: $0 {start <LXC_IDs> | stop | status}"
    exit 1
    ;;
esac
EOF

chmod +x "$KEEPALIVE_PATH"
echo "Keepalive script created and made executable."

echo "Creating systemd service at $SERVICE_PATH..."

cat > "$SERVICE_PATH" << EOF
[Unit]
Description=Proxmox LXC Keepalive Service
After=network.target

[Service]
Type=simple
ExecStart=$KEEPALIVE_PATH start 101 102 103
ExecStop=$KEEPALIVE_PATH stop
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd service created."

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling and starting lxc_keepalive.service..."
systemctl enable lxc_keepalive.service
systemctl start lxc_keepalive.service

echo "Setup complete! The keepalive service is running for containers: 101 102 103"
echo "To change containers, edit $SERVICE_PATH and run:"
echo "  systemctl daemon-reload"
echo "  systemctl restart lxc_keepalive.service"
