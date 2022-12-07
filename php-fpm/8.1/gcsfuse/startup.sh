#!/bin/sh

chown nginx:nginx /var/www/html/var

#Mount volumes
mkdir -p /var/www/html/.config/gcloud
echo "$gke_service_account_key" >> /var/www/html/.config/gcloud/application_default_credentials.base64
base64 -d /var/www/html/.config/gcloud/application_default_credentials.base64 > /var/www/html/.config/gcloud/application_default_credentials.json
rm -rf /var/www/html/.config/gcloud/application_default_credentials.base64
chown -R nginx:nginx /var/www/html/.config/
su - nginx -c 'gcloud auth activate-service-account '"$gke_email"' --key-file=/var/www/html/.config/gcloud/application_default_credentials.json'

mkdir -p /var/www/html/var/export && chown nginx:nginx /var/www/html/var/export
su - nginx -c '/work/bin/gcsfuse '"$gke_bucket_var_export"' /var/www/html/var/export'

mkdir -p /var/www/html/var/importexport && chown nginx:nginx /var/www/html/var/importexport
su - nginx -c '/work/bin/gcsfuse '"$gke_bucket_var_importexport"' /var/www/html/var/importexport'

mkdir -p /var/www/html/var/log && chown nginx:nginx /var/www/html/var/log
su - nginx -c '/work/bin/gcsfuse '"$gke_bucket_var_log"' /var/www/html/var/log'

mkdir -p /var/www/html/var/report && chown nginx:nginx /var/www/html/var/report
su - nginx -c '/work/bin/gcsfuse '"$gke_bucket_var_report"' /var/www/html/var/report'

mkdir -p /var/www/html/pub/media && chown nginx:nginx /var/www/html/pub/media
su - nginx -c '/work/bin/gcsfuse '"$gke_bucket_pub_media"' /var/www/html/pub/media'

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

# Set up SourceGuardian
isArch="$(arch)"
archCode="aarch64"
if [ "$isArch" = "$archCode" ]; then
  tar -xzf /tmp/sourceguardian/loaders.linux-aarch64.tar.gz -C /tmp/sourceguardian
else
  tar -xzf /tmp/sourceguardian/loaders.linux-x86_64.tar.gz -C /tmp/sourceguardian
fi
cp /tmp/sourceguardian/ixed.8.1.lin /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ixed.8.1.lin
chmod 755 /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ixed.8.1.lin
echo 'zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ixed.8.1.lin' > /usr/local/etc/php/conf.d/docker-php-ext-sourceguardian.ini

# Initialize the open ssh server
if [[ -z "$enable_ssh" || "$enable_ssh" == "0" ]]; then
  echo "SSH not enabled"
else
  echo "SSH enabled"
  service ssh start
fi

# Start php-fpm
php-fpm
