# Photo Portfolio Migration Handoff

## What happened so far (on the source server)

### Completed

1. **Fixed `backup.sh`** -- corrected SSL backup path from `./ssl` (didn't exist) to `./certbot/conf/` (where certs actually live), added `sudo` for root-owned cert dirs, and added a `ghost_data` Docker volume export step.

2. **Fixed `docker-compose.yml`** -- added a bind mount so `ghost/content/routes.yaml` maps directly into the Ghost container at `content/settings/routes.yaml:ro`. Previously only `themes/` and `images/` were mounted, and custom routes (the `/tag/` collections page) lived only inside the `ghost_data` Docker volume.

3. **Ran `sudo ./backup.sh`** -- produced a clean manual backup at `./backups/manual/` with timestamp `20260603_042831`:

| File | Size | Contents |
|------|------|----------|
| `ghost-content-20260603_042831.tar.gz` | 269 MB | All themes + uploaded images |
| `database-20260603_042831.sql` | 286 KB | Full MySQL dump (posts, settings, members, tags) |
| `ssl-certs-20260603_042831.tar.gz` | ~60 KB | Let's Encrypt certs, renewal config, dhparams |
| `ghost-data-20260603_042831.tar.gz` | 7.1 KB | Ghost data volume (settings, active routes, redirects) |
| `config-20260603_042831.tar.gz` | 4.4 KB | docker-compose.yml, .env, nginx/ |

### Not yet done

- Restore on homelab (Phase 3 below)
- Cloudflare Tunnel + nginx simplification (Phase 4 below)

---

## Architecture overview

5-service Docker Compose stack on bridge network `app-network`. Only nginx exposes host ports.

```
Internet --> nginx:80/443 --> ghost:2368 --> db:3306 (MySQL 8.0)
                ^                              ^
             certbot                     ghost-backup (daily 2AM)
```

- **COMPOSE_PROJECT_NAME**: `photo-portfolio`
- **Container names**: `photo-portfolio-db`, `photo-portfolio-ghost`, `photo-portfolio-nginx`, `photo-portfolio-certbot`, `photo-portfolio-backup`
- **Current domain**: `photos.tfeuerbach.dev`
- **Current DNS**: A record -> 24.199.85.208 (DigitalOcean), proxied through Cloudflare

### Data locations

| Data | Location | In git? |
|------|----------|---------|
| Theme source + built assets | `ghost/content/themes/tfeuerbach-photos/` | Yes |
| Custom routes | `ghost/content/routes.yaml` | Yes |
| Uploaded images | `ghost/content/images/` (~246 MB) | No |
| MySQL database | Docker volume `photo-portfolio_db_data` (~209 MB) | No |
| Ghost app data | Docker volume `photo-portfolio_ghost_data` (~7 KB) | No |
| SSL certs | `./certbot/conf/` | No |
| Env config | `.env` | No |

### Theme: `tfeuerbach-photos`

Custom Edge-based Ghost theme with: dark/light mode toggle, masonry grid, PhotoSwipe lightbox, mobile bottom nav, randomized home feed, custom `/tag/` collections page. Build uses Gulp + PostCSS. Pre-built assets (`assets/built/`) are committed -- no build step needed for deployment.

---

## Phase 3: Restore on homelab

### Prerequisites

- Docker and Docker Compose installed
- The 5 backup files from `./backups/manual/` transferred to the homelab
- Git repo cloned (or transferred)

### Restore steps

```bash
# 1. Clone repo
git clone <repo-url> photo-portfolio && cd photo-portfolio

# 2. Place .env -- update DOMAIN to match your tunnel/domain setup
#    (.env is also inside config-*.tar.gz if you need to extract it)
cp /path/to/.env .env

# 3. Restore images and themes from ghost-content tarball
tar xzf ghost-content-20260603_042831.tar.gz -C ./ghost/

# 4. Start database only
docker-compose up -d db
# Wait until healthy:
docker-compose ps

# 5. Import database dump
source .env
docker-compose exec -T db mysql \
  -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} \
  < database-20260603_042831.sql

# 6. Restore ghost_data volume
docker run --rm \
  -v photo-portfolio_ghost_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/ghost-data-20260603_042831.tar.gz"

# 7. (Optional) Restore SSL certs -- skip if using Cloudflare Tunnel
mkdir -p certbot
tar xzf ssl-certs-20260603_042831.tar.gz -C ./certbot/

# 8. Start all services
docker-compose up -d

# 9. Verify
curl -k https://localhost
# Ghost admin: https://<DOMAIN>/ghost
# Check: images load, posts render, dark mode works, /tag/ page works
```

### Post-restore checklist

- **Active theme**: Should be `tfeuerbach-photos`. If not, reactivate in Ghost admin > Design.
- **Routes**: `/tag/` collections page should work via the new bind mount. Verify it loads.
- **Domain**: If DOMAIN changed in `.env`, also update Ghost URL in admin (Settings > General) to prevent redirects to the old domain.

---

## Phase 4: Cloudflare Tunnel + nginx simplification

### Current Cloudflare DNS (relevant record)

```
photos.tfeuerbach.dev  A  24.199.85.208  Proxied
```

Other subdomains already use Cloudflare Tunnels (pokedex, stellar-legacy). The photo portfolio should follow the same pattern.

### Plan

Since Cloudflare Tunnel handles SSL termination, we can strip SSL/certbot from the stack entirely:

1. **Remove the `certbot` service** from `docker-compose.yml`
2. **Simplify nginx** to HTTP-only (remove SSL listeners, cert references, HSTS headers)
3. **Remove port 443** from nginx -- only expose port 80 (or an internal port the tunnel connects to)
4. **Add `photos.tfeuerbach.dev`** as a hostname on a Cloudflare Tunnel pointing to `http://localhost:80` (or directly to `http://localhost:2368` to skip nginx entirely -- though nginx adds caching/compression)
5. **Delete the A record** for `photos.tfeuerbach.dev` -- the tunnel CNAME replaces it automatically
6. **Update `.env`** -- `DOMAIN` should stay `photos.tfeuerbach.dev`; the `url` in Ghost config should be `https://photos.tfeuerbach.dev` (Cloudflare provides the HTTPS to visitors)

### Files that need changes for tunnel setup

- `docker-compose.yml` -- remove certbot service, remove port 443 from nginx, remove certbot volume mounts from nginx, remove docker.sock mount
- `nginx/sites-available/default` -- remove the :443 server block or convert to HTTP, keep proxy_pass to ghost:2368
- `nginx/entrypoint.sh` -- remove self-signed cert generation logic
- `init-letsencrypt.sh` -- no longer needed (can keep for reference or delete)

### Order of operations

1. Get the stack running on homelab first (Phase 3)
2. Verify everything works locally (curl, Ghost admin)
3. Make the nginx/compose changes for tunnel mode
4. Set up the tunnel in Cloudflare dashboard
5. Delete the old A record / decommission old server

---

## Important notes

- **COMPOSE_PROJECT_NAME must stay `photo-portfolio`** -- certbot renewal hooks and container names depend on it
- **MySQL PROCESS privilege warning** during backup is harmless -- tablespace metadata isn't needed for restore
- **`backup.sh` now requires `sudo`** for the SSL cert backup (certbot dirs are root-owned)
- **Pre-built theme assets are committed** -- no need to run `yarn install` or `gulp build` unless you change CSS/JS sources
- Ghost caches theme files -- restart Ghost after any template changes: `docker-compose restart ghost`
