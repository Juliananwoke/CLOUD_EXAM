#!/bin/bash

# Define variables
DATABASE_USERNAME="juliana"
DATABASE_PASSWORD="julianagood"
DATABASE_NAME="juliana_DB"

# Installing all required packages
sudo apt update
sudo apt install php -y
sudo apt install apache2 -y
sudo apt install mysql-server -y
sudo apt install php-mysql php-xml php-mbstring php-curl php-zip php-dom git unzip -y

# laravel setup
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo rm -rf /var/www/html/*
sudo chown -R vagrant:vagrant /var/www/html
cd /var/www/html
git clone https://github.com/laravel/laravel.git
cd laravel
sudo chown -R vagrant:vagrant /var/www/html/laravel
composer install
cp .env.example .env
sudo chown -R www-data:www-data /var/www/html/laravel/storage
php artisan key:generate

# Create MySQL user and database
    sudo mysql -uroot <<EOF
CREATE USER '$DATABASE_USERNAME'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$DATABASE_USERNAME'@'localhost';
CREATE DATABASE $DATABASE_NAME;
EOF

# Updating .env file with MySQL configuration
sed -i "s/DB_CONNECTION=sqlite/DB_CONNECTION=mysql\nDB_HOST=127.0.0.1\nDB_PORT=3306\nDB_DATABASE=$DATABASE_NAME\nDB_USERNAME=$DATABASE_USERNAME\nDB_PASSWORD=$DATABASE_PASSWORD/" .env

# Running artisan migrations
php artisan migrate

# Configuring Apache file
sudo bash -c "cat > /etc/apache2/sites-available/laravel.conf <<EOF
<VirtualHost *:80>
    ServerAdmin lamplav.local
    DocumentRoot /var/www/html/laravel/public
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF"
sudo a2dissite 000-default.conf
sudo a2ensite laravel.conf
sudo systemctl reload apache2
