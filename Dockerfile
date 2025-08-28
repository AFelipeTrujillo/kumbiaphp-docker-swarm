# Dockerfile for KumbiaPHP with configurable version and web server
ARG PHP_VERSION=8.1
ARG WEBSERVER=apache

# Use different base images based on web server choice
FROM php:${PHP_VERSION}-apache as apache-base
FROM php:${PHP_VERSION}-fpm as nginx-base

# Final image based on webserver choice
FROM ${WEBSERVER}-base as final

# Arguments for KumbiaPHP version
ARG KUMBIAPHP_VERSION=1.0
ARG WEBSERVER=apache
ARG MEMCACHED_VERSION=""

# Install system dependencies (common for both servers)
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zlib1g-dev \
    pkg-config \
    mariadb-client \
    supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip

# Install Memcached dependencies and extension if version is specified
RUN if [ -n "$MEMCACHED_VERSION" ]; then \
        apt-get install -y libmemcached-dev libmemcached11 libmemcachedutil2 libssl-dev \
        && yes '' | pecl install memcached-3.2.0 \
        && docker-php-ext-enable memcached \
        && echo "session.save_handler = memcached" >> /usr/local/etc/php/php.ini \
        && echo "session.save_path = \"memcached:11211\"" >> /usr/local/etc/php/php.ini; \
    fi

# Install Nginx for nginx variant
RUN if [ "$WEBSERVER" = "nginx" ]; then \
        apt-get install -y nginx; \
    fi

# Enable mod_rewrite for Apache if using Apache
RUN if [ "$WEBSERVER" = "apache" ]; then \
        a2enmod rewrite; \
    fi

# Set working directory
WORKDIR /var/www/html

# Configure permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Copy web server configurations
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
COPY nginx-config.conf /etc/nginx/sites-available/default

# Copy supervisor configuration for nginx+php-fpm
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy initialization script
COPY init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Expose port
EXPOSE 80

# Start command
CMD ["/usr/local/bin/init.sh"] 