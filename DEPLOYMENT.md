# Deployment Summary

## Server Information
- **Server**: medic.gr (Hetzner Ubuntu 24.04 LTS)
- **Resources**: 8GB RAM, 75GB Disk
- **Access**: `ssh -i ~/.ssh/medic root@medic.gr`

## Installation Status

### ✅ Completed
1. **PostgreSQL 16** - Installed and configured
   - Database: `medic`
   - User: `medic`
   - Password: `medic_7581aa195ca01571a4b6680a226206d1`
   
2. **Build Dependencies** - All packages installed
3. **ASDF Version Manager** - Installed at `/opt/asdf`
4. **Firewall (UFW)** - Basic rules configured (SSH, HTTP, HTTPS)

### 🔄 In Progress
- **Erlang 26.2.5** & **Elixir 1.16.3** - Currently compiling via ASDF (10-20 minutes)

### ⏳ Remaining
- Node.js 20 LTS installation
- Nginx final configuration
- SSL certificate setup (Let's Encrypt)

## Generated Files

### Deployment Scripts
- `scripts/setup-server.sh` - Main server setup (currently running)
- `scripts/post-setup.sh` - Post-installation configuration
- `scripts/deploy.sh` - Application deployment script

### Application Configuration
- `lib/medic/release.ex` - Release migration module
- `rel/overlays/bin/migrate` - Migration script for production
- `mix.exs` - Updated with release configuration
- `config/production.env.example` - Production environment template

### Infrastructure
- `scripts/medic.service` - Systemd service file
- `scripts/nginx.conf` - Nginx reverse proxy configuration
- `.github/workflows/deploy.yml` - GitHub Actions CI/CD workflow

### Documentation
- `.agent/workflows/deploy.md` - Deployment workflow
- `.agent/workflows/server-setup.md` - Server setup workflow

## Secrets & Credentials

### Database
```
DATABASE_URL=postgresql://medic:medic_7581aa195ca01571a4b6680a226206d1@localhost/medic
```

### Phoenix
```
SECRET_KEY_BASE=g+5foFw409YRXTnybOYZ+qwHFax/WX8VCaZJqfUD+Vu9y9hMvK2uXT6XXyE80Oha
```

### GitHub Repository
```
git@github.com:BeniamCode/medic.git
```

## Next Steps (After Erlang Compilation)

1. **Upload and run post-setup script:**
   ```bash
   scp -i ~/.ssh/medic scripts/post-setup.sh root@medic.gr:/root/
   ssh -i ~/.ssh/medic root@medic.gr "bash /root/post-setup.sh 'g+5foFw409YRXTnybOYZ+qwHFax/WX8VCaZJqfUD+Vu9y9hMvK2uXT6XXyE80Oha'"
   ```

2. **Add SSH key to GitHub:**
   - The post-setup script will generate an SSH key for the medic user
   - Add it as a deploy key at: https://github.com/BeniamCode/medic/settings/keys

3. **Clone repository:**
   ```bash
   ssh -i ~/.ssh/medic root@medic.gr
   sudo -u medic bash -c 'cd /opt/medic && git clone git@github.com:BeniamCode/medic.git .'
   ```

4. **Update email credentials in `/opt/medic/.env`**

5. **Run initial deployment:**
   ```bash
   ssh -i ~/.ssh/medic root@medic.gr
   sudo -u medic bash /opt/medic/scripts/deploy.sh
   ```

6. **Set up SSL certificate:**
   ```bash
   ssh -i ~/.ssh/medic root@medic.gr
   certbot --nginx -d medic.gr -d www.medic.gr --email your-email@example.com --agree-tos --non-interactive
   ```

7. **Start the application:**
   ```bash
   ssh -i ~/.ssh/medic root@medic.gr
   systemctl start medic
   systemctl status medic
   ```

## GitHub Actions Setup

Add this secret to your GitHub repository:
- Go to: https://github.com/BeniamCode/medic/settings/secrets/actions
- Click "New repository secret"
- **Name**: `SSH_PRIVATE_KEY`
- **Value**: Contents of `~/.ssh/medic` (your private key)

```bash
# On your local machine
cat ~/.ssh/medic
# Copy the entire output
```

After this, every push to `main` will automatically deploy to production!

## Monitoring & Maintenance

### View logs
```bash
ssh -i ~/.ssh/medic root@medic.gr "journalctl -u medic -f"
```

### Check status
```bash
ssh -i ~/.ssh/medic root@medic.gr "systemctl status medic"
```

### Manual deployment
```bash
ssh -i ~/.ssh/medic root@medic.gr
sudo -u medic bash /opt/medic/scripts/deploy.sh
systemctl restart medic
```

### Database access
```bash
ssh -i ~/.ssh/medic root@medic.gr
sudo -u postgres psql -d medic
```
