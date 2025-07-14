#!/bin/sh
set -e

echo "🚀 Starting Azuriom initialization..."

# Функція для очікування бази даних
wait_for_db() {
    echo "⏳ Waiting for database connection..."
    until php -r "
        try {
            \$pdo = new PDO('mysql:host=${DB_HOST};port=${DB_PORT}', '${DB_USERNAME}', '${DB_PASSWORD}');
            echo 'Database connection successful';
            exit(0);
        } catch (Exception \$e) {
            echo 'Database connection failed: ' . \$e->getMessage();
            exit(1);
        }
    "; do
        echo "Database is unavailable - sleeping..."
        sleep 5
    done
}

# Створення необхідних директорій
echo "📁 Creating necessary directories..."
mkdir -p /var/www/azuriom/storage/logs
mkdir -p /var/www/azuriom/storage/app/public
mkdir -p /var/www/azuriom/storage/framework/cache
mkdir -p /var/www/azuriom/storage/framework/sessions
mkdir -p /var/www/azuriom/storage/framework/views
mkdir -p /var/www/azuriom/bootstrap/cache

# Перевірка чи існує Azuriom, якщо ні - завантажуємо
if [ ! -f "/var/www/azuriom/composer.json" ]; then
    echo "📦 Azuriom not found, downloading..."
    cd /tmp
    curl -L https://github.com/Azuriom/Azuriom/archive/refs/heads/master.zip -o azuriom.zip
    unzip -q azuriom.zip
    cp -R Azuriom-master/* /var/www/azuriom/
    cp -R Azuriom-master/.* /var/www/azuriom/ 2>/dev/null || true
    rm -rf Azuriom-master azuriom.zip
    cd /var/www/azuriom
fi

# Встановлення залежностей Composer якщо потрібно
if [ ! -d "/var/www/azuriom/vendor" ]; then
    echo "📚 Installing Composer dependencies..."
    composer install --optimize-autoloader --no-dev --no-interaction --prefer-dist
fi

# Створення .env файлу якщо не існує
if [ ! -f "/var/www/azuriom/.env" ]; then
    echo "⚙️ Creating .env file..."
    cp /var/www/azuriom/.env.example /var/www/azuriom/.env
    
    # Налаштування бази даних
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=${DB_CONNECTION:-mysql}/" /var/www/azuriom/.env
    sed -i "s/DB_HOST=.*/DB_HOST=${DB_HOST:-mysql}/" /var/www/azuriom/.env
    sed -i "s/DB_PORT=.*/DB_PORT=${DB_PORT:-3306}/" /var/www/azuriom/.env
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE:-azuriom}/" /var/www/azuriom/.env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME:-azuriom}/" /var/www/azuriom/.env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD:-}/" /var/www/azuriom/.env
    
    # Налаштування додатку
    sed -i "s/APP_ENV=.*/APP_ENV=${APP_ENV:-production}/" /var/www/azuriom/.env
    sed -i "s/APP_DEBUG=.*/APP_DEBUG=${APP_DEBUG:-false}/" /var/www/azuriom/.env
    sed -i "s|APP_URL=.*|APP_URL=${APP_URL:-http://localhost:8000}|" /var/www/azuriom/.env
fi

# Очікування бази даних
wait_for_db

# Генерація ключа додатку якщо потрібно
if ! grep -q "APP_KEY=base64:" /var/www/azuriom/.env; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force --no-interaction
fi

# Створення symbolic link для storage (якщо не існує)
if [ ! -L "/var/www/azuriom/public/storage" ]; then
    echo "🔗 Creating storage symbolic link..."
    php artisan storage:link --force --no-interaction || true
fi

# Очищення та оптимізація кешу
echo "🧹 Optimizing application..."
php artisan config:clear --no-interaction || true
php artisan route:clear --no-interaction || true
php artisan view:clear --no-interaction || true
php artisan config:cache --no-interaction || true

# Встановлення правильних прав доступу (chmod 775 як рекомендує гайд)
echo "🔒 Setting correct permissions (775 as recommended)..."
find /var/www/azuriom -type f -exec chmod 664 {} \;
find /var/www/azuriom -type d -exec chmod 775 {} \;
chmod -R 775 /var/www/azuriom/storage
chmod -R 775 /var/www/azuriom/bootstrap/cache
chmod 644 /var/www/azuriom/.env

# Перевірка готовності для встановлення
if [ ! -f "/var/www/azuriom/storage/installed" ]; then
    echo "🎯 Azuriom is ready for installation!"
    echo "👉 Visit http://localhost:8000 to complete the installation"
    echo "📊 phpMyAdmin available at http://localhost:8080"
    echo ""
    echo "Database credentials:"
    echo "  Host: mysql"
    echo "  Database: ${DB_DATABASE}"
    echo "  Username: ${DB_USERNAME}"
    echo "  Password: ${DB_PASSWORD}"
else
    echo "✅ Azuriom is already installed!"
fi

echo "🎉 Initialization complete!"

# Запуск PHP-FPM
exec "$@"
