#!/usr/bin/env bash
# RaceSim — apply updates from the repo
# Usage: sudo bash /srv/RaceSim/update.sh

set -euo pipefail

INSTALL_DIR="/srv/RaceSim"
SERVICE_USER="www-data"

echo "=== RaceSim Update ==="

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
echo "  Changes are live at /RaceSim/"
echo "  Logs: sudo journalctl -u nginx -f"
