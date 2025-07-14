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

# Встановлення PHP розширень
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo pdo_pgsql pdo_mysql bcmath zip gd

# Встановлення Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Копіювання entrypoint скрипту
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Встановлення робочої директорії
WORKDIR /var/www/azuriom

# Важливо: НЕ копіюємо файли тут, оскільки вони будуть перезаписані volume mount

# Перемикання на root для entrypoint (для встановлення залежностей)
USER root

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
