#!/bin/bash

# Phoenix Medic App - Deployment Script
# This script runs on the server to deploy the application
# It should be executed as the medic user


# Initialize ASDF
. "$HOME/.asdf/asdf.sh"
# Add manual Elixir path
export PATH="/opt/medic/elixir/bin:$PATH"

APP_NAME="medic"
APP_DIR="/opt/medic"
REPO_URL="git@github.com:BeniamCode/medic.git"
MIX_ENV="prod"

# Define Mix command absolute path
MIX_CMD="/opt/medic/elixir/bin/mix"

echo "=== Deploying Phoenix Medic App ==="
echo "Starting at: $(date)"

cd $APP_DIR

# Pull latest code if repo exists, clone otherwise
if [ -d ".git" ]; then
    echo "[1/7] Pulling latest code from GitHub..."
    git fetch origin
    git reset --hard origin/main
else
    echo "[1/7] Cloning repository..."
    git clone $REPO_URL .
fi

# Install/update dependencies
# [2/7] Installing Hex and Rebar (Skipped - installed manually)
# $MIX_CMD local.hex --force
# $MIX_CMD local.rebar --force

# echo "[3/7] Installing dependencies..."
# $MIX_CMD deps.get --only prod

# Compile the application
echo "[4/7] Compiling application..."
MIX_ENV=prod $MIX_CMD compile

# Install Node.js dependencies and build assets
echo "[5/7] Building assets..."
cd assets
npm install
npm run deploy
cd ..
MIX_ENV=prod $MIX_CMD assets.deploy

# Run database migrations
echo "[6/7] Running database migrations..."
MIX_ENV=prod $MIX_CMD ecto.migrate

# Build release
echo "[7/7] Building production release..."
MIX_ENV=prod $MIX_CMD release --overwrite


echo ""
echo "=== Deployment Complete ==="
echo "Completed at: $(date)"
echo ""
echo "To start the application:"
echo "  sudo systemctl restart medic"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u medic -f"
