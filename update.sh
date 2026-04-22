#!/usr/bin/env bash
# Apply updates from the repo to the live site.
# Usage: sudo bash /srv/meshtastic-race-simulator/update.sh
set -euo pipefail

INSTALL_DIR="/srv/meshtastic-race-simulator"

if [ ! -d "$INSTALL_DIR/.git" ]; then
  echo "Error: $INSTALL_DIR is not a git repo. Run setup.sh first."
  exit 1
fi

echo "==> Pulling latest changes..."
git -C "$INSTALL_DIR" pull --ff-only

echo "==> Setting permissions..."
chown -R root:www-data "$INSTALL_DIR"
find "$INSTALL_DIR" -type d -exec chmod 750 {} +
find "$INSTALL_DIR" -type f -exec chmod 640 {} +

echo ""
echo "Done — changes are live at /MeshraceSim/"
