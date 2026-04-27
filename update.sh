#!/usr/bin/env bash
# MeshRace Simulator — apply updates from the repo
# Usage: sudo bash /srv/meshtastic-race-simulator/update.sh

set -euo pipefail

INSTALL_DIR="/srv/meshtastic-race-simulator"
SERVICE_USER="www-data"

echo "=== MeshRace Simulator Update ==="

if [ ! -d "${INSTALL_DIR}/.git" ]; then
  echo "Error: ${INSTALL_DIR} is not a git repo. Run setup.sh first."
  exit 1
fi

echo "Pulling latest changes..."
git -C "${INSTALL_DIR}" -c safe.directory="${INSTALL_DIR}" pull --ff-only

echo "Setting permissions..."
chown -R root:"${SERVICE_USER}" "${INSTALL_DIR}"
find "${INSTALL_DIR}" -type d -exec chmod 750 {} +
find "${INSTALL_DIR}" -type f -exec chmod 640 {} +

echo ""
echo "=== Update complete ==="
echo "  Changes are live at /MeshraceSim/"
echo "  Logs: sudo journalctl -u nginx -f"
