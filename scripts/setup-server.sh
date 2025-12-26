#!/bin/bash

# Phoenix Medic App - Alternative Server Setup Script
# Uses ASDF for Erlang/Elixir installation (more reliable)
# Run as root on Ubuntu 24.04 LTS

set -e  # Exit on error

echo "=== Phoenix Medic Server Setup (Alternative Method) ==="
echo "Starting at: $(date)"

# Update system packages
echo ""
echo "[1/8] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential build tools and dependencies
echo ""
echo "[2/8] Installing build essentials and dependencies..."
apt-get install -y \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libwxgtk3.2-dev \
    libwxgtk-webview3.2-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    xsltproc \
    fop \
    libxml2-utils \
    libncurses-dev \
    openjdk-11-jdk \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw

# Install PostgreSQL 16
echo ""
echo "[3/8] Installing PostgreSQL 16..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql-16 postgresql-contrib-16

# Configure PostgreSQL
echo ""
echo "[4/8] Configuring PostgreSQL database..."
DB_PASSWORD="medic_$(openssl rand -hex 16)"
sudo -u postgres psql -c "CREATE DATABASE medic;" 2>/dev/null || echo "Database already exists"
sudo -u postgres psql -c "CREATE USER medic WITH PASSWORD '${DB_PASSWORD}';" 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE medic TO medic;"
sudo -u postgres psql -c "ALTER USER medic WITH SUPERUSER;"
echo ""
echo "Database password: ${DB_PASSWORD}"
echo "Save this password! You'll need it for DATABASE_URL in .env"
echo ""

# Install ASDF version manager
echo ""
echo "[5/8] Installing ASDF version manager..."
git clone https://github.com/asdf-vm/asdf.git /opt/asdf --branch v0.14.0 || echo "ASDF already installed"
echo '. /opt/asdf/asdf.sh' >> /etc/profile.d/asdf.sh
export ASDF_DIR="/opt/asdf"
. /opt/asdf/asdf.sh

# Install Erlang and Elixir via ASDF
echo ""
echo "[6/8] Installing Erlang 26 and Elixir 1.16 via ASDF..."
asdf plugin add erlang || echo "Erlang plugin already added"
asdf plugin add elixir || echo "Elixir plugin already added"
asdf install erlang 26.2.5
asdf install elixir 1.16.3-otp-26
asdf global erlang 26.2.5
asdf global elixir 1.16.3-otp-26

# Install Node.js 20 LTS
echo ""
echo "[7/8] Installing Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Nginx
echo ""
echo "[8/8] Installing Nginx..."
apt-get install -y nginx

# Configure UFW Firewall
echo ""
echo "Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https

# Create application directory and user
echo ""
echo "Creating application directory..."
mkdir -p /opt/medic
useradd -r -s /bin/bash -d /opt/medic medic 2>/dev/null || echo "User medic already exists"
chown -R medic:medic /opt/medic

# Configure ASDF for medic user
echo '. /opt/asdf/asdf.sh' >> /opt/medic/.bashrc
sudo -u medic bash -c 'cd ~ && source .bashrc && asdf reshim'

# Display versions
echo ""
echo "=== Installation Complete ==="
echo "Erlang version:"
. /opt/asdf/asdf.sh && erl -version
echo ""
echo "Elixir version:"
. /opt/asdf/asdf.sh && elixir --version
echo ""
echo "Node.js version:"
node --version
echo ""
echo "PostgreSQL version:"
psql --version
echo ""
echo "Nginx version:"
nginx -v
echo ""
echo "=== IMPORTANT: Save this information ==="
echo "Database name: medic"
echo "Database user: medic"
echo "Database password: ${DB_PASSWORD}"
echo ""
echo "Completed at: $(date)"
