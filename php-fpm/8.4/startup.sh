#!/bin/sh

chown -R nginx:nginx /var/www/html/var

# Set up cron
if [[ -z "$cron_jobs" || "$cron_jobs" == "0" ]]; then
  echo "No cron jobs were set"
else
  echo "Setting up cron jobs"
  echo "$cron_jobs" > /var/www/cron-jobs.base64
  base64 -d /var/www/cron-jobs.base64 > /var/www/cron-jobs
  echo  >> /var/www/cron-jobs
  rm -rf /var/www/cron-jobs.base64
  chmod 777 /var/www/cron-jobs
  su - nginx -c 'crontab /var/www/cron-jobs'
  rm /var/www/cron-jobs
  service cron start
fi

# Put back app/etc/env.php and app/etc/config.php to non editable
cd /var/www/html/ && chmod -R 750 app/etc/env.php
cd /var/www/html/ && chmod -R 750 app/etc/config.php

# Upgrade DB and set production mode
if [[ -z "$setup_upgrade" || "$setup_upgrade" == "0" ]]; then
  echo "Not running setup:upgrade"
else
  cd /var/www/html/ && yes | /usr/local/bin/composer install --no-dev --ignore-platform-reqs

  # Zip the pub/static folder with all its contents and save it
  cd /var/www/html/ && zip -r /var/www/html/pub/static.zip pub/static

  php /var/www/html/bin/magento setup:upgrade --keep-generated
  php /var/www/html/bin/magento setup:di:compile

  # Unzip the pub/static folder
  cd /var/www/html/ && unzip -o /var/www/html/pub/static.zip -d /var/www/html/pub/
  rm -rf /var/www/html/pub/static.zip

  cd /var/www/html/ && yes | /usr/local/bin/composer dump-autoload -o
fi

isArch="$(arch)"
archCode="aarch64"
if [ "$isArch" = "$archCode" ]; then
  curl --create-dirs -O --output-dir /tmp/sourceguardian https://www.sourceguardian.com/loaders/download/loaders.linux-aarch64.tar.gz
  # curl --create-dirs -O --output-dir /tmp/ioncube https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz
  tar -xzf /tmp/sourceguardian/loaders.linux-aarch64.tar.gz -C /tmp/sourceguardian
  # tar -xzf /tmp/ioncube/ioncube_loaders_lin_aarch64.tar.gz -C /tmp/ioncube
else
  curl --create-dirs -O --output-dir /tmp/sourceguardian https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz
  # curl --create-dirs -O --output-dir /tmp/ioncube http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
  tar -xzf /tmp/sourceguardian/loaders.linux-x86_64.tar.gz -C /tmp/sourceguardian
  # tar -xzf /tmp/ioncube/ioncube_loaders_lin_x86-64.tar.gz -C /tmp/ioncube
fi

# Set up SourceGuardian
phpVersion="$(php -v | awk 'NR==1 {print $2}' | cut -d'.' -f1-2)"
mkdir -p /usr/local/lib/php/extensions/no-debug-non-zts-20240924
cp /tmp/sourceguardian/ixed.$phpVersion.lin /usr/local/lib/php/extensions/no-debug-non-zts-20240924/ixed.$phpVersion.lin
chmod 755 /usr/local/lib/php/extensions/no-debug-non-zts-20240924/ixed.$phpVersion.lin
echo "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20240924/ixed.$phpVersion.lin" > /usr/local/etc/php/conf.d/docker-php-ext-sourceguardian.ini

# Install xDebug
if [[ -z "$xdebug" || "$xdebug" == "0" ]]; then
    echo "No xdebug"
else
    echo "Enabling xdebug"
    pecl install xdebug-3.4.2
    echo 'zend_extension=xdebug.so
xdebug.mode=develop,debug
xdebug.client_host=localhost
xdebug.start_with_request=trigger
xdebug.client_port="9003"
xdebug.start_with_request=yes
xdebug.connect_timeout_ms=2000
xdebug.start_upon_error=yes
xdebug.log=/tmp/xdebug.log
' > /usr/local/etc/php/conf.d/xdebug.ini
fi

# Install Blackfire 
if [[ -z "$blackfire" || "$blackfire" == "0" ]]; then
    echo "No blackfire"
else
    echo "Enabling blackfire"
    
    #Install blackfire
    apt install blackfire -y
    apt install blackfire-php -y
    service blackfire-agent stop
    chown -R nginx:nginx /etc/blackfire/
    mkdir -p /var/run/blackfire/ && chown -R nginx:nginx /var/run/blackfire/
    chmod -R 775 /var/run/blackfire
fi

# Initialize the open ssh server
if [[ -z "$enable_ssh" || "$enable_ssh" == "0" ]]; then
  echo "SSH not enabled"
else
  echo "SSH enabled"
  service ssh start
fi

# Start Mailhog
if [[ -z "$mailhog" || "$mailhog" == "0" ]]; then
    echo "No mailhog"
else
    echo "Starting mailhog"
    /usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &
fi

# Start php-fpm
php-fpm
