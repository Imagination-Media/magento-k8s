#!/bin/bash

# Delete var and generated content
rm -rf /var/www/html/var/*
rm -rf /var/www/html/generated/*

# Clean Redis cache
node /var/www/util/redis-cli/lib/src/index.js -h redis flushall

# Run magento setup:upgrade
php /var/www/html/bin/magento setup:upgrade
