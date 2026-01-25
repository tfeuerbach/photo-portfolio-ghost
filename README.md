<h1 align="center">Photo Portfolio - Dockerized Ghost Deployment</h1>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-Ready-blue.svg" alt="Docker"></a>
  <a href="https://ghost.org/"><img src="https://img.shields.io/badge/Ghost-Latest-brightgreen.svg" alt="Ghost"></a>
  <a href="http://makeapullrequest.com"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

<p align="center">
  A fully containerized Ghost-based photo portfolio using a customized <a href="https://ghost.org/themes/edge/">Edge theme</a>.<br>
  Self-hosted, automated, and production-ready.
</p>

<p align="center">
  <strong>Live Example:</strong> <a href="https://photos.tfeuerbach.dev">photos.tfeuerbach.dev</a>
</p>

## Features

### Infrastructure
- Self-hosted Ghost CMS with complete Docker setup - one command deployment
- Automated SSL certificates via Let's Encrypt with automatic renewal
- Daily automated backups (database + content)
- Nginx reverse proxy with compression and caching

### Theme Customizations
- **Dark/light mode toggle** with persistent user preference and animated sun/moon icon
- **Collections page** (`/tag/`) that groups photos by tag with preview grids
- **Random photo layout** that shuffles photos on each page load for variety
- **Masonry photo grid** for Pinterest-style responsive layout
- **Custom mobile experience** with fixed bottom navigation bar
- **PhotoSwipe lightbox** for full-screen photo viewing
- **Custom favicon set** for all devices and PWA support

## Quick Start for Your Own Deployment

### Prerequisites

- A server with Docker and Docker Compose installed
- A domain name pointing to your server (A records for `yourdomain.com` and `www.yourdomain.com`)
- Ports 80 and 443 open

### Setup Instructions

1. **Clone this repository**:
   ```bash
   git clone https://github.com/yourusername/photo-portfolio.git
   cd photo-portfolio
   ```

2. **Create your `.env` file**:
   ```bash
   cp .env.example .env
   nano .env
   ```
   
   Update these required variables:
   - `MYSQL_ROOT_PASSWORD` - Database root password
   - `MYSQL_PASSWORD` - Ghost database password
   - `DOMAIN` - Your domain name (e.g., `photos.yourdomain.com`)
   - `EMAIL` - Email for SSL certificate notifications
   
   Optional: Add Gmail credentials if you want Ghost to send emails (password resets, etc.)

3. **Make the init script executable**:
   ```bash
   chmod +x init-letsencrypt.sh backup.sh
   ```

4. **Run the one-time setup**:
   ```bash
   ./init-letsencrypt.sh
   ```
   
   This script will:
   - Download TLS parameters
   - Create temporary SSL certificates
   - Start all services (MySQL, Ghost, Nginx)
   - Obtain real Let's Encrypt certificates
   - Set up automatic certificate renewal
   
   **Takes about 30-60 seconds!**

5. **Access your site**:
   - **Frontend**: https://yourdomain.com
   - **Admin**: https://yourdomain.com/ghost
   
   On first visit to `/ghost`, create your admin account and start uploading photos!

### Repository Structure

- **Infrastructure**: Docker Compose, Nginx configs, SSL automation
- **Theme**: Customized Edge theme in `ghost/content/themes/`
- **Scripts**: Backup and SSL certificate management
- **Not tracked**: Your content (images, database, certificates)


## Management Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Manual backup
./backup.sh

# Update Ghost
docker-compose pull ghost
docker-compose up -d ghost

# Reload Nginx after certificate renewal (usually not needed)
docker-compose exec nginx nginx -s reload

# Rebuild nginx after config changes
docker-compose build nginx
docker-compose up -d nginx

# Check certificate status
docker-compose exec certbot certbot certificates
```

## Backup & Restore

The `ghost-backup` service automatically backs up your entire site daily at 2 AM:
- Database dump (posts, settings)
- Uploaded photos
- Theme customizations
- Ghost configuration

**Manual backup**: Run `./backup.sh` anytime

**Restore process**:
```bash
# Stop services
docker-compose down

# Restore files and database
tar -xzf backups/backup-YYYY-MM-DD.tar.gz -C ./
mysql -u root -p ghost < backups/ghost-backup.sql

# Restart
docker-compose up -d
```

## Theme Customizations

This deployment uses a customized version of the [Edge theme](https://ghost.org/themes/edge/) called `tfeuerbach-photos` with enhancements for a photo portfolio experience.

### Custom Features

| Feature | Description | Key Files |
|---------|-------------|-----------|
| **Dark/Light Mode** | Toggle in header with localStorage persistence | `dark-mode.css`, `dark-mode.js` |
| **Collections Page** | Browse all tags at `/tag/` with photo previews | `custom-tags.hbs`, `collections.css`, `routes.yaml` |
| **Random Layout** | Photos shuffle on each page load | `main.js` |
| **Masonry Grid** | Pinterest-style responsive photo layout | `masonry.css`, `masonry.pkgd.min.js` |
| **Mobile Layout** | Fixed bottom nav bar, hamburger menu | `mobile-responsive.css`, `mobile-menu.js` |
| **PhotoSwipe** | Full-screen lightbox for photos | `pswp.hbs`, `pswp.css` |
| **Custom Favicons** | Complete icon set for all devices | `assets/icons/` |

Theme files live in `ghost/content/themes/tfeuerbach-photos/` and are version controlled.

### Theme Development

```bash
# Navigate to theme directory
cd ghost/content/themes/tfeuerbach-photos/

# Install dependencies
yarn install

# Development mode with live reload
yarn dev

# Build production assets
gulp build

# Run theme validation
yarn test

# Create distributable zip
yarn zip
```

After editing CSS/JS, rebuild with `gulp build`. After editing `.hbs` templates, restart Ghost: `docker-compose restart ghost`.

Theme files are tracked in git so you can version control your customizations.

### Using a Different Theme

1. Download any Ghost theme to `ghost/content/themes/your-theme/`
2. Go to https://yourdomain.com/ghost → Settings → Design
3. Activate your new theme
4. Commit the theme to git: `git add ghost/content/themes/your-theme/`

### Changing Domain

1. Update `DOMAIN` in `.env`
2. Remove old certificates: `sudo rm -rf ./certbot/conf/*`
3. Re-run setup: `./init-letsencrypt.sh`

## Architecture

### Storage Strategy

- **Git-tracked**: Theme customizations, infrastructure code
- **Host-mounted**: Uploaded photos (for easy backup)
- **Docker volumes**: Database, logs, Ghost data

### Services

All services run in an isolated Docker network (only ports 80/443 exposed):
- **Ghost (latest)** - CMS with Edge theme
- **MySQL 8.0** - Database backend
- **Nginx** - Reverse proxy, SSL termination
- **Certbot** - Certificate automation
- **Ghost-Backup** - Daily site backups

## Security

- Isolated Docker network (only 80/443 exposed)
- SSL/TLS with HSTS and strong ciphers
- HTTPS-only admin panel
- No database port exposure

## Common Issues

**Ghost won't start**
```bash
# Check database connection
docker-compose logs db ghost
```

**SSL certificate issues**
```bash
# Verify DNS and ports first, then:
docker-compose down
sudo rm -rf ./certbot/conf/*
./init-letsencrypt.sh
```

**Theme not updating**
```bash
docker-compose restart ghost
```

Note: If using Cloudflare, set SSL mode to "Full" (not "Full (strict)") until certificates are working.

## License

MIT License - use freely for personal or commercial projects. See [LICENSE](LICENSE) for details.

The Edge theme is developed by Ghost Foundation and has its own license.

## Contributing

Found a bug? Have an idea for improvement? PRs and issues welcome!

## Credits

- **Ghost**: [ghost.org](https://ghost.org)
- **Edge Theme**: [ghost.org/themes/edge](https://ghost.org/themes/edge/)
- **Ghost Backup**: [bennetimo/ghost-backup](https://github.com/bennetimo/docker-ghost-backup)

Built with ❤️ for photographers who want to own their platform.