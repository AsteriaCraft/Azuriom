#!/bin/sh

# Перевірка та встановлення залежностей
if [ ! -d "/var/www/azuriom/vendor" ]; then
    echo "Installing Composer dependencies..."
    composer install --optimize-autoloader --no-dev --no-interaction
fi

# Copy .env.example to .env if it doesn't exist
if [ ! -f /var/www/azuriom/.env ]; then
    cp /var/www/azuriom/.env.example /var/www/azuriom/.env
    echo "Created .env file from .env.example"
fi

# Ensure directories exist
mkdir -p /var/www/azuriom/storage/logs
mkdir -p /var/www/azuriom/storage/app/public
mkdir -p /var/www/azuriom/bootstrap/cache

# Generate application key if not set
if [ -f /var/www/azuriom/.env ] && ! grep -q "APP_KEY=base64:" /var/www/azuriom/.env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Set proper permissions
chown -R www-data:www-data /var/www/azuriom/storage
chown -R www-data:www-data /var/www/azuriom/bootstrap/cache
chmod -R 775 /var/www/azuriom/storage
chmod -R 775 /var/www/azuriom/bootstrap/cache

exec "$@"
