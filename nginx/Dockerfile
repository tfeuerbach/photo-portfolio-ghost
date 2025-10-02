FROM nginx:alpine

# Install openssl for generating temporary certificates
RUN apk add --no-cache openssl

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY sites-available/ /etc/nginx/sites-available/

# Create sites-enabled directory and link
RUN mkdir -p /etc/nginx/sites-enabled && \
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Copy and set permissions for entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
