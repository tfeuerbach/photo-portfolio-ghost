<h1 align="center">Photo Portfolio - Dockerized Ghost Deployment</h1>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/Docker-Ready-blue.svg" alt="Docker"></a>
  <a href="https://ghost.org/"><img src="https://img.shields.io/badge/Ghost-Latest-brightgreen.svg" alt="Ghost"></a>
  <a href="http://makeapullrequest.com"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

<p align="center">
  A fully containerized Ghost-based photo portfolio using a customized <a href="https://ghost.org/themes/edge/">Edge theme</a>.<br>
  Self-hosted on a homelab, securely exposed via Cloudflare Tunnel.
</p>

<p align="center">
  <strong>Live Example:</strong> <a href="https://photos.tfeuerbach.dev">photos.tfeuerbach.dev</a>
</p>

## Features

### Infrastructure
- Self-hosted Ghost CMS with complete Docker setup - one command deployment
- Secure public access via Cloudflare Tunnel - no open ports required
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

## Architecture

```
Internet --> Cloudflare Edge (TLS) --> cloudflared --> nginx:80 --> ghost:2368 --> db:3306
                                                                                    ^
                                                                              ghost-backup (2 AM)
```

All services run in an isolated Docker network. Only port 80 is bound to `127.0.0.1` (localhost only) - the Cloudflare Tunnel is the sole ingress path to the site. Cloudflare handles TLS termination, so nginx operates in HTTP-only mode.

### Services

| Service | Image | Role |
|---------|-------|------|
| **ghost** | `ghost:latest` | Ghost CMS on port 2368 |
| **db** | `mysql:8.0` | Database backend, not exposed externally |
| **nginx** | Custom Alpine build | HTTP reverse proxy with caching and compression |
| **cloudflared** | `cloudflare/cloudflared` | Cloudflare Tunnel client |
| **ghost-backup** | `bennetimo/ghost-backup` | Daily backups at 2 AM |

### Storage Strategy

- **Git-tracked**: Theme customizations, infrastructure code, tunnel config
- **Host-mounted**: Uploaded photos (for easy backup), tunnel credentials (gitignored)
- **Docker volumes**: Database, logs, Ghost data

## Quick Start for Your Own Deployment

### Prerequisites

- A machine with Docker and Docker Compose installed
- A Cloudflare account with your domain added
- [`cloudflared` CLI](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) installed locally

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
   - `COMPOSE_PROJECT_NAME` - Keep as `photo-portfolio`
   - `MYSQL_ROOT_PASSWORD` - Database root password
   - `MYSQL_PASSWORD` - Ghost database password
   - `DOMAIN` - Your domain name (e.g., `photos.yourdomain.com`)

   Optional: Add Gmail credentials if you want Ghost to send emails (password resets, etc.)

3. **Authenticate with Cloudflare and create your tunnel**:
   ```bash
   cloudflared tunnel login
   # Opens a browser - log in and select your zone

   cloudflared tunnel create photo-portfolio
   # Note the tunnel ID and credentials file path

   cloudflared tunnel route dns photo-portfolio photos.yourdomain.com
   # Creates a CNAME record automatically
   ```

4. **Set up tunnel credentials for Docker**:
   ```bash
   mkdir -p cloudflared
   cp ~/.cloudflared/<TUNNEL-ID>.json cloudflared/credentials.json
   chmod 644 cloudflared/credentials.json
   ```

   Update `cloudflared/config.yml` with your tunnel ID and domain:
   ```yaml
   tunnel: <YOUR-TUNNEL-ID>
   credentials-file: /etc/cloudflared/credentials.json

   ingress:
     - hostname: photos.yourdomain.com
       service: http://nginx:80
     - service: http_status:404
   ```

5. **Start all services**:
   ```bash
   docker compose up -d
   ```

6. **Access your site**:
   - **Frontend**: https://yourdomain.com
   - **Admin**: https://yourdomain.com/ghost

   On first visit to `/ghost`, create your admin account and start uploading photos!

### Repository Structure

- **Infrastructure**: Docker Compose, Nginx configs, Cloudflare Tunnel config
- **Theme**: Customized Edge theme in `ghost/content/themes/`
- **Scripts**: Backup management
- **Not tracked**: Your content (images, database, tunnel credentials)

## Management Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f [ghost|db|nginx|cloudflared|ghost-backup]

# Manual backup
./backup.sh

# Update Ghost
docker compose pull ghost
docker compose up -d ghost

# Rebuild nginx after config changes
docker compose build nginx
docker compose up -d nginx

# Check tunnel status
docker compose logs cloudflared
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
docker compose down

# Restore Ghost content (images + themes)
tar xzf ghost-content-TIMESTAMP.tar.gz -C ./ghost/

# Start database
docker compose up -d db
# Wait for healthy, then import dump
docker compose exec -T db mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < database-TIMESTAMP.sql

# Restore Ghost data volume
docker run --rm \
  -v photo-portfolio_ghost_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/ghost-data-TIMESTAMP.tar.gz"

# Start everything
docker compose up -d
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

After editing CSS/JS, rebuild with `gulp build`. After editing `.hbs` templates, restart Ghost: `docker compose restart ghost`.

Theme files are tracked in git so you can version control your customizations.

### Using a Different Theme

1. Download any Ghost theme to `ghost/content/themes/your-theme/`
2. Go to https://yourdomain.com/ghost → Settings → Design
3. Activate your new theme
4. Commit the theme to git: `git add ghost/content/themes/your-theme/`

### Changing Domain

1. Update `DOMAIN` in `.env`
2. Update `cloudflared/config.yml` hostname
3. Route DNS: `cloudflared tunnel route dns photo-portfolio new-domain.example.com`
4. Restart: `docker compose restart cloudflared nginx`
5. Update Ghost URL in admin panel (Settings → General)

## Security

- No ports exposed to the public internet - Cloudflare Tunnel is the sole ingress
- Nginx binds to `127.0.0.1:80` only (localhost)
- TLS termination handled by Cloudflare's edge network
- Database not exposed externally
- Tunnel credentials gitignored

## Common Issues

**Ghost won't start**
```bash
docker compose logs db ghost
```

**Site not reachable publicly**
```bash
# Check tunnel connections (should show "Registered tunnel connection")
docker compose logs cloudflared

# Verify DNS
dig photos.tfeuerbach.dev
# Should show CNAME to cfargotunnel.com
```

**Theme not updating**
```bash
docker compose restart ghost
```

## License

MIT License - use freely for personal or commercial projects. See [LICENSE](LICENSE) for details.

The Edge theme is developed by Ghost Foundation and has its own license.

## Contributing

Found a bug? Have an idea for improvement? PRs and issues welcome!

## Credits

- **Ghost**: [ghost.org](https://ghost.org)
- **Edge Theme**: [ghost.org/themes/edge](https://ghost.org/themes/edge/)
- **Ghost Backup**: [bennetimo/ghost-backup](https://github.com/bennetimo/docker-ghost-backup)
- **Cloudflare Tunnel**: [developers.cloudflare.com](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

Built with ❤️ for photographers who want to own their platform.
