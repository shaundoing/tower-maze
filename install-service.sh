#!/usr/bin/env bash
set -e

SERVICE=tower-maze
UNIT=/etc/systemd/system/${SERVICE}.service

echo "Installing ${SERVICE} systemd service..."
sudo cp "$(dirname "$0")/${SERVICE}.service" "$UNIT"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE"
sudo systemctl restart "$SERVICE"

echo ""
echo "Status:"
sudo systemctl status "$SERVICE" --no-pager -l

echo ""
echo "Serving at http://127.0.0.1:8765"
echo "Run 'sudo systemctl stop $SERVICE' to stop."
