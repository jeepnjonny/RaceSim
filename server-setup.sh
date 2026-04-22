#!/usr/bin/env bash
# Initial server setup — clone the repo and configure nginx.
# Run once as root (or with sudo) on your nginx host.
# Usage: sudo bash server-setup.sh
set -euo pipefail

REPO_URL="https://github.com/jeepnjonny/meshtastic-race-simulator.git"
INSTALL_DIR="/opt/meshtastic-race-simulator"
NGINX_CONF="/etc/nginx/conf.d/meshrace.conf"

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
  echo "==> Repo already cloned — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "==> Cloning repo to $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ── 3. Permissions ────────────────────────────────────────────────────────────
echo "==> Setting permissions..."
chown -R www-data:www-data "$INSTALL_DIR"
find "$INSTALL_DIR" -type d -exec chmod 755 {} +
find "$INSTALL_DIR" -type f -exec chmod 644 {} +

# ── 4. nginx config ───────────────────────────────────────────────────────────
echo "==> Writing nginx config: $NGINX_CONF"
cat > "$NGINX_CONF" << EOF
location /MeshraceSim/ {
    alias $INSTALL_DIR/;
    index index.html;
    try_files \$uri \$uri/ /MeshraceSim/index.html;
    add_header Cache-Control "public, max-age=3600";
}
EOF

echo "==> Testing nginx config..."
nginx -t

echo "==> Reloading nginx..."
systemctl reload nginx

echo ""
echo "Done! App is live at: http://$(hostname -f)/MeshraceSim/"
echo ""
echo "To apply future updates:"
echo "  cd $INSTALL_DIR && git pull && sudo bash update.sh"
