FROM php:8.5-fpm-alpine

WORKDIR /var/www/html

# Install core runtime utilities and system configurations
RUN apk add --no-cache \
    shadow \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    bash

# Compile only standard native PHP extensions (No external internet required)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql zip

# Pull down Composer binary natively
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN usermod -u 1000 www-data && groupmod -g 1000 www-data \
    && chown -R www-data:www-data /var/www/html

USER www-data

EXPOSE 9000

# Startup script: installs vendors if missing, waits for DB, runs migrations
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["php-fpm"]
