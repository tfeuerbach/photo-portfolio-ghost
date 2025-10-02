#!/bin/sh

# Default domain if not set
DOMAIN=${DOMAIN:-localhost}

echo "Configuring Nginx for domain: $DOMAIN"

# Substitute environment variables in Nginx config
envsubst '${DOMAIN}' < /etc/nginx/sites-available/default > /etc/nginx/sites-available/default.tmp
mv /etc/nginx/sites-available/default.tmp /etc/nginx/sites-available/default

CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
CERT_FILE="$CERT_DIR/fullchain.pem"
KEY_FILE="$CERT_DIR/privkey.pem"

# Check if real Let's Encrypt certificates exist (not self-signed)
if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    # Check if it's a Let's Encrypt certificate
    if openssl x509 -in "$CERT_FILE" -noout -issuer 2>/dev/null | grep -q "Let's Encrypt"; then
        echo "Valid Let's Encrypt certificates found. Starting Nginx..."
    else
        echo "Self-signed certificates found. Keeping them for now..."
        echo "Run init-letsencrypt.sh to get real Let's Encrypt certificates."
    fi
else
    echo "SSL certificates not found. Creating temporary self-signed certificates..."
    
    # Create certificate directory
    mkdir -p "$CERT_DIR"
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/CN=$DOMAIN" \
        2>/dev/null
    
    echo "Temporary certificates created. Run init-letsencrypt.sh to get real certificates."
fi

# Start Nginx
exec nginx -g 'daemon off;'

