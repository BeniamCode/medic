---
description: Deploy application to production server
---

# Production Deployment Workflow

This workflow describes how to deploy the Medic application to the production server.

## Automated Deployment (via GitHub Actions)

The easiest and recommended way to deploy is to push to the `main` branch:

```bash
# Make your changes and commit
git add .
git commit -m "your commit message"

// turbo
# Push to main branch (triggers automatic deployment)
git push origin main
```

The GitHub Actions workflow will automatically:
1. Run tests (if configured)
2. SSH into the production server
3. Pull latest code
4. Build the release
5. Run migrations
6. Restart the application

Monitor the deployment at: https://github.com/BeniamCode/medic/actions

## Manual Deployment

If you need to deploy manually:

```bash
# SSH into the server
ssh -i ~/.ssh/medic root@medic.gr

# Switch to medic user and go to app directory
sudo -u medic -i
cd /opt/medic

// turbo
# Run the deployment script
bash scripts/deploy.sh

// turbo
# Restart the application
exit  # Back to root user
systemctl restart medic

// turbo
# Check status
systemctl status medic

# View logs
journalctl -u medic -f --lines=50
```

## Rollback

If you need to rollback to a previous version:

```bash
ssh -i ~/.ssh/medic root@medic.gr
cd /opt/medic

// turbo
# Check git log to find commit to rollback to
sudo -u medic git log --oneline -n 10

# Rollback to specific commit
sudo -u medic git reset --hard <commit-hash>

# Rebuild and restart
sudo -u medic bash scripts/deploy.sh
systemctl restart medic
```

## Running Migrations Manually

```bash
ssh -i ~/.ssh/medic root@medic.gr
cd /opt/medic
sudo -u medic MIX_ENV=prod mix ecto.migrate
```

## Troubleshooting

### Check application logs
```bash
ssh -i ~/.ssh/medic root@medic.gr
journalctl -u medic -f
```

### Check if app is running
```bash
ssh -i ~/.ssh/medic root@medic.gr
systemctl status medic
```

### Restart the application
```bash
ssh -i ~/.ssh/medic root@medic.gr
systemctl restart medic
```

### Check database connectivity
```bash
ssh -i ~/.ssh/medic root@medic.gr
sudo -u postgres psql -d medic -c "SELECT version();"
```
