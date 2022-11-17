#!/bin/sh

# Set up production mode
#su - www-data -c 'php /var/www/html/bin/magento deploy:mode:set production --skip-compilation'

# Set up cron
if [[ -z "$cron_jobs" ]]; then
  echo "No cron jobs were set"
else
  echo "Setting up cron jobs"
  echo "$cron_jobs" > /var/www/cron-jobs.base64
  base64 -d /var/www/cron-jobs.base64 > /var/www/cron-jobs
  rm -rf /var/www/cron-jobs.base64
  chmod 777 /var/www/cron-jobs
  su - www-data -c 'crontab /var/www/cron-jobs'
  rm /var/www/cron-jobs
fi

# Upgrade DB and set production mode
if [[ -z "$setup_upgrade" || "$setup_upgrade" == "0" ]]; then
  echo "Not running setup:upgrade"
else
  su - www-data -c 'php /var/www/html/bin/magento setup:upgrade --keep-generated'
  su - www-data -c 'php /var/www/html/bin/magento setup:di:compile'
  su - www-data -c 'php /var/www/html/bin/magento bin/magento setup:static-content:deploy -f'
fi

# Back app/etc/env.php and app/etc/config.php to non editable
cd /var/www/html/ && chmod -R 750 app/etc/env.php
cd /var/www/html/ && chmod -R 750 app/etc/config.php

#Initialize the open ssh server
service ssh start

#Start php-fpm
php-fpm
