#!/usr/bin/env bash
# MeshRace Simulator — first-time server setup
# Run as a user with sudo access on your nginx host
# Usage: bash setup.sh [--ssl]

set -euo pipefail

REPO_URL="https://github.com/jeepnjonny/meshtastic-race-simulator.git"
INSTALL_DIR="/srv/meshtastic-race-simulator"
SERVICE_USER="www-data"
HOSTNAME="${HOSTNAME:-$(hostname -f)}"
SSL=${1:-""}

echo "=== MeshRace Simulator Setup ==="

# ── 1. Dependencies ────────────────────────────────────────────────────────────
echo "Checking dependencies..."
if ! command -v git &>/dev/null; then
  sudo apt-get update -qq && sudo apt-get install -y git
fi
if ! command -v nginx &>/dev/null; then
  sudo apt-get update -qq && sudo apt-get install -y nginx
fi
echo "  git $(git --version | awk '{print $3}') OK"
echo "  nginx OK"

# ── 2. Clone or pull ───────────────────────────────────────────────────────────
if [ -d "${INSTALL_DIR}/.git" ]; then
  echo "Repo already present — pulling latest..."
  sudo git -C "${INSTALL_DIR}" -c safe.directory="${INSTALL_DIR}" pull --ff-only
else
  echo "Cloning repo to ${INSTALL_DIR}..."
  sudo git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

# ── 3. Permissions ─────────────────────────────────────────────────────────────
echo "Setting permissions..."
sudo chown -R root:"${SERVICE_USER}" "${INSTALL_DIR}"
sudo find "${INSTALL_DIR}" -type d -exec chmod 750 {} +
sudo find "${INSTALL_DIR}" -type f -exec chmod 640 {} +

# ── 4. Remove legacy conf.d file if present ────────────────────────────────────
LEGACY_CONF="/etc/nginx/conf.d/meshrace.conf"
if [ -f "${LEGACY_CONF}" ]; then
  echo "Removing legacy config: ${LEGACY_CONF}"
  sudo rm -f "${LEGACY_CONF}"
fi

# ── 5. nginx ───────────────────────────────────────────────────────────────────
LOCATION_BLOCK="
    location /MeshraceSim/ {
        alias ${INSTALL_DIR}/;
        index index.html;
        try_files \\\$uri \\\$uri/ /MeshraceSim/index.html;
        add_header Cache-Control \"public, max-age=3600\";
    }"

if [ ! -d /etc/nginx/sites-available ]; then
  echo "  nginx sites-available not found — copy the location block into your nginx config manually."
else
  EXISTING_CONF=$(grep -rl "server_name.*${HOSTNAME}" /etc/nginx/sites-enabled/ 2>/dev/null | head -1 || true)

  if [ -n "${EXISTING_CONF}" ]; then
    if grep -q "location /MeshraceSim/" "${EXISTING_CONF}"; then
      echo "  nginx: /MeshraceSim/ location already present in ${EXISTING_CONF}"
    else
      echo "  nginx: injecting /MeshraceSim/ location into ${EXISTING_CONF}"
      sudo sed -i "$ s|^\s*}|${LOCATION_BLOCK}\n}|" "${EXISTING_CONF}"
      sudo nginx -t && sudo systemctl reload nginx
      echo "  nginx reloaded"
    fi
  else
    echo "  nginx: no existing server block for ${HOSTNAME}, deploying standalone config"
    sudo tee /etc/nginx/sites-available/meshrace > /dev/null <<EOF
# MeshRace Simulator — static file server
# Serving at http://${HOSTNAME}/MeshraceSim/
#
# If you already have a server block for this hostname, copy the
# location block into that file and remove this one.

server {
    listen 80;
    listen [::]:80;
    server_name ${HOSTNAME};

    location /MeshraceSim/ {
        alias ${INSTALL_DIR}/;
        index index.html;
        try_files \$uri \$uri/ /MeshraceSim/index.html;
        add_header Cache-Control "public, max-age=3600";
    }
}
EOF
    sudo ln -sf /etc/nginx/sites-available/meshrace /etc/nginx/sites-enabled/meshrace
    sudo nginx -t && sudo systemctl reload nginx
    echo "  nginx configured"
  fi
fi

# ── 6. SSL via certbot ─────────────────────────────────────────────────────────
if [ "${SSL}" = "--ssl" ]; then
  echo "Setting up SSL with certbot..."
  if ! command -v certbot &>/dev/null; then
    sudo apt-get install -y certbot python3-certbot-nginx
  fi
  sudo certbot --nginx -d "${HOSTNAME}" --non-interactive --agree-tos -m "admin@${HOSTNAME}" || true
  echo "  SSL configured (check output above for any errors)"
else
  echo ""
  echo "  TIP: Re-run with --ssl to configure HTTPS via certbot:"
  echo "       bash setup.sh --ssl"
fi

echo ""
echo "=== Setup complete ==="
echo "  App:    http://${HOSTNAME}/MeshraceSim/"
echo "  Update: sudo bash ${INSTALL_DIR}/update.sh"
echo "  Logs:   sudo journalctl -u nginx -f"
