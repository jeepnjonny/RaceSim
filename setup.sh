#!/usr/bin/env bash
# Initial server setup — clone the repo and configure nginx.
# Run once as root (or with sudo) on your nginx host.
#
# Usage:
#   sudo bash setup.sh
#
# Optional: set SERVER_NAME to your domain before running, e.g.:
#   SERVER_NAME=example.com sudo bash setup.sh
set -euo pipefail

REPO_URL="https://github.com/jeepnjonny/meshtastic-race-simulator.git"
INSTALL_DIR="/srv/meshtastic-race-simulator"
SITE_NAME="meshrace"
SITES_AVAILABLE="/etc/nginx/sites-available/$SITE_NAME"
SITES_ENABLED="/etc/nginx/sites-enabled/$SITE_NAME"
SERVER_NAME="${SERVER_NAME:-$(hostname -f)}"

# ── 1. Dependencies ────────────────────────────────────────────────────────────
echo "==> Checking dependencies..."
if ! command -v git &>/dev/null; then
  apt-get update -qq && apt-get install -y git
fi
if ! command -v nginx &>/dev/null; then
  apt-get update -qq && apt-get install -y nginx
fi

# ── 2. Clone or update repo ───────────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "==> Repo already present — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "==> Cloning repo to $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ── 3. Permissions ────────────────────────────────────────────────────────────
# root owns the repo so git operations work under sudo.
# www-data group gets read access to serve files; no write access needed.
echo "==> Setting permissions..."
chown -R root:www-data "$INSTALL_DIR"
find "$INSTALL_DIR" -type d -exec chmod 750 {} +
find "$INSTALL_DIR" -type f -exec chmod 640 {} +

# ── 4. nginx site config ──────────────────────────────────────────────────────
echo "==> Writing $SITES_AVAILABLE..."
cat > "$SITES_AVAILABLE" << EOF
# MeshRace Simulator
# Serving at http://${SERVER_NAME}/MeshraceSim/
#
# If you already have a server block for this hostname, copy the
# location block below into that file and remove this one.

server {
    listen 80;
    listen [::]:80;
    server_name ${SERVER_NAME};

    location /MeshraceSim/ {
        alias ${INSTALL_DIR}/;
        index index.html;
        try_files \$uri \$uri/ /MeshraceSim/index.html;
        add_header Cache-Control "public, max-age=3600";
    }
}
EOF

# Enable the site (idempotent)
if [ ! -L "$SITES_ENABLED" ]; then
  echo "==> Enabling site..."
  ln -s "$SITES_AVAILABLE" "$SITES_ENABLED"
else
  echo "==> Site already enabled."
fi

# ── 5. Test and reload ────────────────────────────────────────────────────────
echo "==> Testing nginx config..."
nginx -t

echo "==> Reloading nginx..."
systemctl reload nginx

echo ""
echo "Done! App is live at: http://${SERVER_NAME}/MeshraceSim/"
echo ""
echo "To apply future updates:"
echo "  cd $INSTALL_DIR && sudo git pull && sudo bash update.sh"
