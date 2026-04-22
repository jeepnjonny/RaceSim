#!/usr/bin/env bash
# Apply updates after git pull.
# Usage: cd /opt/meshtastic-race-simulator && git pull && sudo bash update.sh
set -euo pipefail

INSTALL_DIR="/opt/meshtastic-race-simulator"

if [ ! -d "$INSTALL_DIR/.git" ]; then
  echo "Error: $INSTALL_DIR is not a git repo. Run server-setup.sh first."
  exit 1
fi

echo "==> Pulling latest changes..."
git -C "$INSTALL_DIR" pull --ff-only

echo "==> Setting permissions..."
chown -R www-data:www-data "$INSTALL_DIR"
find "$INSTALL_DIR" -type f -exec chmod 644 {} +

echo ""
echo "Done — changes are live at /MeshraceSim/"
