FROM php:8.3-fpm-alpine

# Встановлення системних залежностей
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    libzip-dev \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    openssl \
    nodejs \
    npm

# Встановлення PHP розширень (додав gd для зображень, що потрібно для Azuriom)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo pdo_pgsql pdo_mysql bcmath zip gd

# Встановлення Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Копіювання entrypoint скрипту
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Встановлення робочої директорії
WORKDIR /var/www/azuriom

# Копіювання файлів проекту
COPY --chown=www-data:www-data . /var/www/azuriom/

# Встановлення залежностей як root
USER root
RUN composer install --optimize-autoloader --no-dev --no-interaction

# Встановлення прав та перемикання на www-data
RUN chown -R www-data:www-data /var/www/azuriom
RUN chmod -R 755 /var/www/azuriom
RUN chmod -R 775 storage bootstrap/cache 2>/dev/null || true

USER www-data

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
