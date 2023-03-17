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
  cd /var/www/html/ && /usr/local/bin/composer install --no-dev --ignore-platform-reqs
  php /var/www/html/bin/magento setup:upgrade --keep-generated
  php /var/www/html/bin/magento setup:di:compile
  php /var/www/html/bin/magento setup:static-content:deploy -f --jobs "$magento_static_content_jobs"
  cd /var/www/html/ && /usr/local/bin/composer dump-autoload -o
fi

isArch="$(arch)"
archCode="aarch64"
if [ "$isArch" = "$archCode" ]; then
  curl --create-dirs -O --output-dir /tmp/sourceguardian https://www.sourceguardian.com/loaders/download/loaders.linux-aarch64.tar.gz
  curl --create-dirs -O --output-dir /tmp/ioncube https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz
  tar -xzf /tmp/sourceguardian/loaders.linux-aarch64.tar.gz -C /tmp/sourceguardian
  tar -xzf /tmp/ioncube/ioncube_loaders_lin_aarch64.tar.gz -C /tmp/ioncube
else
  curl --create-dirs -O --output-dir /tmp/sourceguardian https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz
  curl --create-dirs -O --output-dir /tmp/ioncube http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
  tar -xzf /tmp/sourceguardian/loaders.linux-x86_64.tar.gz -C /tmp/sourceguardian
  tar -xzf /tmp/ioncube/ioncube_loaders_lin_x86-64.tar.gz -C /tmp/ioncube
fi

# Set up SourceGuardian
phpVersion="$(php -v | awk 'NR==1 {print $2}' | cut -d'.' -f1-2)"
cp /tmp/sourceguardian/ixed.$phpVersion.lin /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ixed.$phpVersion.lin
chmod 755 /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ixed.$phpVersion.lin
echo "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ixed.$phpVersion.lin" > /usr/local/etc/php/conf.d/docker-php-ext-sourceguardian.ini

# Set up IonCube
mv /tmp/ioncube/ioncube/ioncube_loader_lin_$phpVersion.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902
echo "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ioncube_loader_lin_$phpVersion.so" > /usr/local/etc/php/conf.d/docker-php-ext-ioncube.ini

# Gcsfuse
if [[ -z "$gcsfuse_enable" || "$gcsfuse_enable" == "0" ]]; then
  echo "Gcsfuse not enabled"
else
  echo "Gcsfuse enabled"
  
  #Mount volumes
  mkdir -p /root/.config/gcloud && echo "$gke_service_account_key" >> /root/.config/gcloud/application_default_credentials.base64
  base64 -d /root/.config/gcloud/application_default_credentials.base64 > /root/.config/gcloud/application_default_credentials.json
  rm -rf /root/.config/gcloud/application_default_credentials.base64
  gcloud auth activate-service-account "$gke_email" --key-file=/root/.config/gcloud/application_default_credentials.json

  mkdir -p /var/www/html/var/export && chown nginx:nginx /var/www/html/var/export
  /work/bin/gcsfuse --implicit-dirs --limit-ops-per-sec "0" --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_export" /var/www/html/var/export

  mkdir -p /var/www/html/var/importexport && chown nginx:nginx /var/www/html/var/importexport
  /work/bin/gcsfuse --implicit-dirs --limit-ops-per-sec "0" --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_importexport" /var/www/html/var/importexport

  mkdir -p /var/www/html/var/log && chown nginx:nginx /var/www/html/var/log
  /work/bin/gcsfuse --implicit-dirs --limit-ops-per-sec "0" --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_log" /var/www/html/var/log

  mkdir -p /var/www/html/var/report && chown nginx:nginx /var/www/html/var/report
  /work/bin/gcsfuse --implicit-dirs --limit-ops-per-sec "0" --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_report" /var/www/html/var/report

  mkdir -p /var/www/html/pub/media && chown nginx:nginx /var/www/html/pub/media
  /work/bin/gcsfuse --implicit-dirs --limit-ops-per-sec "0" --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_pub_media" /var/www/html/pub/media
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
