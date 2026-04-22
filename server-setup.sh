#!/usr/bin/env bash
# Run once on your nginx server to prepare the deployment target.
# Usage: sudo bash server-setup.sh
set -euo pipefail

DEPLOY_DIR="/var/www/html/MeshraceSim"
NGINX_CONF="/etc/nginx/conf.d/meshrace.conf"

echo "==> Creating deploy directory: $DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
chown www-data:www-data "$DEPLOY_DIR"
chmod 755 "$DEPLOY_DIR"

echo "==> Installing nginx location config: $NGINX_CONF"
cat > "$NGINX_CONF" << 'EOF'
location /MeshraceSim/ {
    alias /var/www/html/MeshraceSim/;
    index index.html;
    try_files $uri $uri/ /MeshraceSim/index.html;
    add_header Cache-Control "public, max-age=3600";
}
EOF

echo "==> Testing nginx config..."
nginx -t

echo "==> Reloading nginx..."
systemctl reload nginx

echo ""
echo "Done. The app will be available at http://$(hostname -f)/MeshraceSim/ after first deploy."
echo ""
echo "Next steps:"
echo "  1. Add these secrets to your GitHub repo (Settings > Secrets > Actions):"
echo "     SSH_HOST  — your server IP or hostname"
echo "     SSH_USER  — SSH login user (must have write access to $DEPLOY_DIR)"
echo "     SSH_KEY   — private key for that user (paste the full PEM)"
echo "  2. Push to the 'main' branch — GitHub Actions will deploy automatically."
