#!/bin/sh

DOMAIN=${DOMAIN:-localhost}

echo "Configuring Nginx for domain: $DOMAIN"

envsubst '${DOMAIN}' < /etc/nginx/sites-available/default > /etc/nginx/sites-available/default.tmp
mv /etc/nginx/sites-available/default.tmp /etc/nginx/sites-available/default

exec nginx -g 'daemon off;'
