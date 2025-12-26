#!/bin/bash

# Post-Setup Configuration Script
# Run this after the main setup script completes
# Run as root

set -e

echo "=== Post-Setup Configuration ==="

DB_PASSWORD="medic_7581aa195ca01571a4b6680a226206d1"
SECRET_KEY_BASE="$1"  # Pass as argument

if [ -z "$SECRET_KEY_BASE" ]; then
    echo "Error: Please provide SECRET_KEY_BASE as first argument"
    echo "Generate one with: mix phx.gen.secret"
    exit 1
fi

# Create environment file
echo "[1/5] Creating environment file..."
cat > /opt/medic/.env << EOF
# Production Environment Variables
DATABASE_URL=postgresql://medic:${DB_PASSWORD}@localhost/medic
POOL_SIZE=20

PHX_SERVER=true
PHX_HOST=medic.gr
PORT=4000
SECRET_KEY_BASE=${SECRET_KEY_BASE}

# Email Configuration (Update these with real values)
HI_USERNAME=hi@medic.gr
GMAIL_SMTP_APP=REPLACE_WITH_APP_PASSWORD
APPOINTMENTS_SMTP_APP=REPLACE_WITH_APP_PASSWORD

# Backblaze B2 Storage (if using)
B2_KEY_ID=REPLACE_IF_USING
B2_APPLICATION_KEY=REPLACE_IF_USING
B2_BUCKET_ID=REPLACE_IF_USING
B2_BUCKET_NAME=REPLACE_IF_USING

MIX_ENV=prod
EOF

chown medic:medic /opt/medic/.env
chmod 600 /opt/medic/.env

echo "[2/5] Configuring Nginx..."
cp /opt/medic/scripts/nginx.conf /etc/nginx/sites-available/medic
ln -sf /etc/nginx/sites-available/medic /etc/nginx/sites-enabled/medic
rm -f /etc/nginx/sites-enabled/default
nginx -t

echo "[3/5] Installing certbot for SSL..."
apt-get install -y certbot python3-certbot-nginx
mkdir -p /var/www/certbot

echo "[4/5] Installing systemd service..."
cp /opt/medic/scripts/medic.service /etc/systemd/system/medic.service
systemctl daemon-reload
systemctl enable medic

echo "[5/5] Configuring SSH for medic user (for GitHub access)..."
sudo -u medic bash << 'EOFMEDIC'
cd ~
# Generate SSH key for GitHub access
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "medic-production@medic.gr" -f ~/.ssh/id_ed25519 -N ""
    echo ""
    echo "=== ADD THIS PUBLIC KEY TO GITHUB ==="
    cat ~/.ssh/id_ed25519.pub
    echo "======================================"
fi
EOFMEDIC

echo ""
echo "=== Post-Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Add the SSH public key above to GitHub:"
echo "   https://github.com/BeniamCode/medic/settings/keys"
echo ""
echo "2. Update email credentials in /opt/medic/.env"
echo ""
echo "3. Clone the repository:"
echo "   sudo -u medic bash -c 'cd /opt/medic && git clone git@github.com:BeniamCode/medic.git .'"
echo ""
echo "4. Run initial deployment:"
echo "   sudo -u medic bash /opt/medic/scripts/deploy.sh"
echo ""
echo "5. Get SSL certificate:"
echo "   certbot --nginx -d medic.gr -d www.medic.gr --email YOUR_EMAIL@example.com"
echo ""
echo "6. Start the application:"
echo "   systemctl start medic"
echo ""
