#!/bin/sh
# Copy .env.example to .env if it doesn't exist
if [ ! -f /var/www/azuriom/.env ]; then
    cp /var/www/azuriom/.env.example /var/www/azuriom/.env
    echo "Created .env file from .env.example"
fi

# Ensure storage and bootstrap/cache directories have correct permissions
mkdir -p /var/www/azuriom/storage/logs
mkdir -p /var/www/azuriom/storage/app/public
mkdir -p /var/www/azuriom/bootstrap/cache

# Generate application key if not set
if ! grep -q "APP_KEY=base64:" /var/www/azuriom/.env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

exec "$@"
