#!/bin/bash

# Initialization script for KumbiaPHP

echo "Starting KumbiaPHP configuration..."

# Wait for MySQL to be available
echo "Waiting for MySQL connection..."
while ! mysqladmin ping -h mysql -u $MYSQL_USER -p$MYSQL_PASSWORD --silent; do
    echo "MySQL is not ready yet. Waiting..."
    sleep 2
done

echo "MySQL is ready!"

# Configure database for KumbiaPHP if configuration doesn't exist
if [ ! -f "/var/www/html/default/app/config/databases.php" ]; then
    echo "Creating database configuration..."
    mkdir -p /var/www/html/default/app/config
    
    cat > /var/www/html/default/app/config/databases.php << EOF
<?php
/**
 * Database configuration
 */

return [
    'development' => [
        'host' => 'mysql',
        'username' => '$MYSQL_USER',
        'password' => '$MYSQL_PASSWORD',
        'name' => '$MYSQL_DATABASE',
        'type' => 'mysql',
        'charset' => 'utf8'
    ],
    'production' => [
        'host' => 'mysql',
        'username' => '$MYSQL_USER',
        'password' => '$MYSQL_PASSWORD',
        'name' => '$MYSQL_DATABASE',
        'type' => 'mysql',
        'charset' => 'utf8'
    ]
];
EOF
fi

# Now KumbiaPHP is mounted from local ./app directory
# Just ensure the structure is correct
echo "Verifying KumbiaPHP structure..."
if [ ! -d "/var/www/html/default" ]; then
    echo "Error: KumbiaPHP not found. Make sure ./app contains KumbiaPHP code."
    exit 1
fi

# KumbiaPHP structure is now completely in the local ./app directory
# Just configure file permissions
echo "Setting up file permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Configuration completed. Starting web server..."

# Start web server based on WEBSERVER environment variable
if [ "$WEBSERVER" = "nginx" ]; then
    echo "Starting Nginx with PHP-FPM..."
    # Remove default nginx site and enable our configuration
    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    
    # Test nginx configuration
    nginx -t
    
    # Start supervisor (nginx + php-fpm)
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
else
    echo "Starting Apache..."
    # Start Apache in foreground
    apache2-foreground
fi 