FROM php:8.3-cli-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring zip bcmath \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . /app

RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

ENV APP_ENV=production
ENV LOG_CHANNEL=stderr
# Free/trial RAM is tight when MySQL shares the project budget.
ENV PHP_MEMORY_LIMIT=128M

# Cap PHP memory for artisan / built-in server.
RUN printf "memory_limit=128M\n" > /usr/local/etc/php/conf.d/zz-memory.ini

EXPOSE 8080

RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
