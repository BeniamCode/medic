---
description: One-time server setup for production
---

# Server Setup Workflow

This is a one-time setup for the production server. Once complete, you won't need to run these steps again.

## Initial Server Setup

The main setup script has already been created and run. If you need to set up a new server:

```bash
# Upload and run the setup script
scp -i ~/.ssh/medic scripts/setup-server.sh root@medic.gr:/root/
ssh -i ~/.ssh/medic root@medic.gr "bash /root/setup-server.sh"
```

## Post-Setup Configuration

### 1. Configure Nginx

```bash
ssh -i ~/.ssh/medic root@medic.gr

# Copy nginx config
scp -i ~/.ssh/medic scripts/nginx.conf root@medic.gr:/etc/nginx/sites-available/medic

# Enable the site (on the server)
ln -s /etc/nginx/sites-available/medic /etc/nginx/sites-enabled/medic
rm -f /etc/nginx/sites-enabled/default

# Test nginx config
nginx -t

# Restart nginx
systemctl restart nginx
```

### 2. Set up SSL Certificates

```bash
ssh -i ~/.ssh/medic root@medic.gr

# Install certbot
apt-get install -y certbot python3-certbot-nginx

# Create directory for ACME challenge
mkdir -p /var/www/certbot

# Get SSL certificate (replace email)
certbot --nginx -d medic.gr -d www.medic.gr --email your-email@example.com --agree-tos --non-interactive

# Certbot will automatically configure nginx
# Test automatic renewal
certbot renew --dry-run
```

### 3. Clone Repository and Configure Application

```bash
ssh -i ~/.ssh/medic root@medic.gr

# Switch to medic user
sudo -u medic -i

# Navigate to app directory
cd /opt/medic

# Clone the repository
git clone git@github.com:BeniamCode/medic.git .

# Note: You'll need to add the server's SSH key to GitHub
# Generate SSH key if needed:
ssh-keygen -t ed25519 -C "medic-production"
cat ~/.ssh/id_ed25519.pub
# Add this public key to GitHub as a deploy key
```

### 4. Configure Environment Variables

```bash
ssh -i ~/.ssh/medic root@medic.gr

# Create .env file
sudo -u medic nano /opt/medic/.env

# Use the template from config/production.env.example
# Generate secrets:
# SECRET_KEY_BASE: Run locally: mix phx.gen.secret
# Database password: The one created during setup or create new one

# IMPORTANT: Fill in all required environment variables:
# - DATABASE_URL
# - SECRET_KEY_BASE
# - Email credentials
# - etc.
```

### 5. Install and Configure Systemd Service

```bash
ssh -i ~/.ssh/medic root@medic.gr

# Copy service file
cp /opt/medic/scripts/medic.service /etc/systemd/system/medic.service

# Reload systemd
systemctl daemon-reload

# Enable service to start on boot
systemctl enable medic

# Don't start yet - need to build first
```

### 6. Initial Deployment

```bash
ssh -i ~/.ssh/medic root@medic.gr

# Run initial deployment
sudo -u medic bash /opt/medic/scripts/deploy.sh

# Start the service
systemctl start medic

# Check status
systemctl status medic

# View logs
journalctl -u medic -f
```

## Verify Installation

```bash
# Check all services are running
ssh -i ~/.ssh/medic root@medic.gr "systemctl status postgresql nginx medic"

# Test the application
curl -I https://medic.gr

# Check firewall
ssh -i ~/.ssh/medic root@medic.gr "ufw status"
```

## GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

1. Go to: https://github.com/BeniamCode/medic/settings/secrets/actions
2. Add new secret: `SSH_PRIVATE_KEY`
3. Value: Contents of your local `~/.ssh/medic` file

```bash
# Copy your private key (on your local machine)
cat ~/.ssh/medic
# Copy the entire output and paste as the secret value
```

## Optional: Typesense Installation

If your app uses Typesense for search:

```bash
ssh -i ~/.ssh/medic root@medic.gr

# Install Typesense
curl -O https://dl.typesense.org/releases/typesense-server-0.25.2-linux-amd64.tar.gz
tar -xzf typesense-server-0.25.2-linux-amd64.tar.gz
mv typesense-server /usr/local/bin/

# Create systemd service for Typesense
# ... (additional configuration needed based on your requirements)
```
