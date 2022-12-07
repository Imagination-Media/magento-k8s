#!/bin/sh

#ARG admin_domain
#ARG frontend_domain
#ARG admin_store
#ARG frontend_store
#ARG magento_mode
#ARG php_fpm_service
#ARG ip_addresses
#ARG gke_email
#ARG gke_service_account_key
#ARG gke_bucket_var_export
#ARG gke_bucket_var_importexport
#ARG gke_bucket_var_log
#ARG gke_bucket_var_report
#ARG gke_bucket_pub_media

chown -R nginx:nginx /var/www/html/var

#Mount volumes
mkdir -p /root/.config/gcloud && echo "$gke_service_account_key" >> /root/.config/gcloud/application_default_credentials.base64
base64 -d /root/.config/gcloud/application_default_credentials.base64 > /root/.config/gcloud/application_default_credentials.json
rm -rf /root/.config/gcloud/application_default_credentials.base64
gcloud auth activate-service-account "$gke_email" --key-file=/root/.config/gcloud/application_default_credentials.json

mkdir -p /var/www/html/var/export && chown nginx:nginx /var/www/html/var/export
/work/bin/gcsfuse --implicit-dirs --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_export" /var/www/html/var/export

mkdir -p /var/www/html/var/importexport && chown nginx:nginx /var/www/html/var/importexport
/work/bin/gcsfuse --implicit-dirs --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_importexport" /var/www/html/var/importexport

mkdir -p /var/www/html/var/log && chown nginx:nginx /var/www/html/var/log
/work/bin/gcsfuse --implicit-dirs --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_log" /var/www/html/var/log

mkdir -p /var/www/html/var/report && chown nginx:nginx /var/www/html/var/report
/work/bin/gcsfuse --implicit-dirs --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_var_report" /var/www/html/var/report

mkdir -p /var/www/html/pub/media && chown nginx:nginx /var/www/html/pub/media
/work/bin/gcsfuse --implicit-dirs --dir-mode "775" --uid "$(id -u nginx)" --gid "$(id -g nginx)" -o allow_other  "$gke_bucket_pub_media" /var/www/html/pub/media

# Adjust admin store domain
sed -i -e "s/admin.mydemo.com/$admin_domain/g" /etc/nginx/nginx.conf

# Adjust storefront domain
sed -i -e "s/mydemo.com/$frontend_domain/g" /etc/nginx/nginx.conf

# Set admin store code
sed -i -e "s/adminstore/$admin_store/g" /etc/nginx/nginx.conf

# Set frontend store code
sed -i -e "s/defaultstore/$frontend_store/g" /etc/nginx/nginx.conf

# Set magento mode
if [ -z "${magento_mode}" ]; then
    sed -i -e "s/magentomode/production/g" /etc/nginx/nginx.conf
else
    sed -i -e "s/magentomode/${magento_mode}/g" /etc/nginx/nginx.conf
fi

# Set php-fpm service name
sed -i -e "s/phpservice.namespace:9001/$php_fpm_service/g" /etc/nginx/nginx.conf

# Set up ip addresses
if [ -z "${ip_addresses}" ]; then
   sed -i -e "s/allow ipAddresses;/#allow ipAddresses;/g" /etc/nginx/nginx.conf
   sed -i -e "s/deny all;/#deny all;/g" /etc/nginx/nginx.conf
else
    sed -i -e "s/ipAddresses/${ip_addresses}/g" /etc/nginx/nginx.conf
fi

exec /docker-entrypoint.sh $@
