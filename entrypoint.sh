#!/bin/sh
# Container entrypoint: prepare the Laravel app, then hand off to php-fpm.
set -e

cd /var/www/html

# Install vendor dependencies if they are missing from the bind mount
if [ ! -d vendor ]; then
    composer install --no-interaction --optimize-autoloader
fi

# Wait until the database accepts connections (depends_on only guarantees
# mysqld is healthy, not that it can serve this app yet)
echo "Waiting for database..."
until php -r 'try { new PDO("mysql:host=".getenv("DB_HOST").";port=".getenv("DB_PORT"), getenv("DB_USERNAME"), getenv("DB_PASSWORD")); exit(0); } catch (Throwable $e) { exit(1); }'; do
    sleep 2
done

# Run migrations (and seed in local environments)
php artisan migrate --force
if [ "$APP_ENV" = "local" ]; then
    php artisan db:seed --force || true
fi

# Execute the container's main command (php-fpm)
exec "$@"
