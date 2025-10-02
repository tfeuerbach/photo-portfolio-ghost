#!/bin/bash

# Backup script for the photo portfolio application

# Source environment variables from .env file
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

BACKUP_DIR="./backups/manual"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Creating backup at $TIMESTAMP..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup Ghost content
echo "Backing up Ghost content..."
tar -czf "$BACKUP_DIR/ghost-content-$TIMESTAMP.tar.gz" -C ./ghost content/

# Backup database
echo "Backing up database..."
docker-compose exec -T db mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > "$BACKUP_DIR/database-$TIMESTAMP.sql"

# Backup SSL certificates
echo "Backing up SSL certificates..."
tar -czf "$BACKUP_DIR/ssl-certs-$TIMESTAMP.tar.gz" -C ./ssl .

# Backup configuration files
echo "Backing up configuration..."
tar -czf "$BACKUP_DIR/config-$TIMESTAMP.tar.gz" docker-compose.yml .env nginx/

echo "Backup complete! Files saved to $BACKUP_DIR/"
echo "Content: ghost-content-$TIMESTAMP.tar.gz"
echo "Database: database-$TIMESTAMP.sql"
echo "SSL: ssl-certs-$TIMESTAMP.tar.gz"
echo "Config: config-$TIMESTAMP.tar.gz"
