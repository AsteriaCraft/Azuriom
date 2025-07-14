# Використовуємо PHP 8.3-FPM Alpine для кращої продуктивності
FROM php:8.3-fpm-alpine

# Встановлення системних залежностей
RUN apk add --no-cache \
    git \
    curl \
    zip \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    postgresql-dev \
    mysql-client \
    openssl \
    ca-certificates \
    supervisor \
    && rm -rf /var/cache/apk/*

# Встановлення PHP розширень згідно з вимогами Azuriom
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        ctype \
        curl \
        gd \
        intl \
        mbstring \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        tokenizer \
        xml \
        xmlwriter \
        zip

# Встановлення Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Встановлення Node.js і npm (для frontend assets)
RUN apk add --no-cache nodejs npm

# Копіювання entrypoint і конфігурацій
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/php.ini /usr/local/etc/php/conf.d/azuriom.ini
RUN chmod +x /usr/local/bin/entrypoint.sh

# Встановлення робочої директорії
WORKDIR /var/www/azuriom

# Встановлення правильних прав користувача
RUN addgroup -g 1000 azuriom \
    && adduser -D -s /bin/sh -u 1000 -G azuriom azuriom \
    && chown -R azuriom:azuriom /var/www

# Створення необхідних директорій
RUN mkdir -p /var/www/azuriom/storage/logs \
    && mkdir -p /var/www/azuriom/storage/app/public \
    && mkdir -p /var/www/azuriom/bootstrap/cache \
    && chown -R azuriom:azuriom /var/www/azuriom

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
