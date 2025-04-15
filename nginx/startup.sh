#!/bin/sh

#ARG admin_domain
#ARG frontend_domain
#ARG admin_store
#ARG frontend_store
#ARG magento_mode
#ARG php_fpm_service
#ARG ip_addresses

# Check if admin_domain and admin_store are not provided
if [ -z "${admin_domain}" ] || [ -z "${admin_store}" ]; then
    echo "admin_domain or admin_store not provided. Using nginx-no-admin.conf."
    rm -f /etc/nginx/nginx.conf
    mv /etc/nginx/nginx-no-admin.conf /etc/nginx/nginx.conf
fi

chown -R nginx:nginx /var/www/html/var

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

# Set up ip addresses (front)
if [ -z "${ip_addresses}" ]; then
   echo "No storefront restriction"
else
    sed -i -e "s/#allow storefrontIp;/allow ${ip_addresses};/g" /etc/nginx/nginx.conf
    sed -i -e "s/#storefrontdenyall;/deny all;/g" /etc/nginx/nginx.conf
fi

# Set up ip addresses (admin)
if [ -z "${admin_ip_addresses}" ]; then
   echo "No admin restriction"
else
    sed -i -e "s/#allow adminIp;/allow ${admin_ip_addresses};/g" /etc/nginx/nginx.conf
    sed -i -e "s/#admindenyall;/deny all;/g" /etc/nginx/nginx.conf
fi

exec /docker-entrypoint.sh $@
