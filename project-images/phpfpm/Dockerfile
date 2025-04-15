FROM ghcr.io/imagination-media/magento-k8s/php-fpm:8.1
#FROM ghcr.io/imagination-media/magento-k8s/php-fpm:8.1-gcsfuse

ARG SSH_AUTHORIZED_KEYS
ARG APP_ETC_ENV

# User root
USER root

# Copy authorized keys
RUN mkdir -p /home/nginx/.ssh
RUN echo "$SSH_AUTHORIZED_KEYS" >> /home/nginx/.ssh/authorized_keys
RUN chown -R nginx:nginx /home/nginx/.ssh/
RUN chmod 400 /home/nginx/.ssh/authorized_keys

# Copy repository
COPY repository.zip /var/www/html/
RUN unzip -q /var/www/html/repository.zip -d /var/www/html
RUN rm -rf /var/www/html/repository.zip

# Create app/etc/env.php from environment variable
RUN mkdir -p /var/www/html/app/etc
RUN rm -rf /var/www/html/app/etc/env.php
RUN echo "$APP_ETC_ENV" | base64 --decode > /var/www/html/app/etc/env.php

# Adjust permissions
RUN chown -R nginx:nginx /var/www/html/

# Set the permissions for the Magento directory
RUN cd /var/www/ && chown -R root:nginx html && chmod -R 750 html
RUN cd /var/www/html/ && chmod -R 770 generated/code
RUN cd /var/www/html/ && chmod -R 770 generated/metadata
RUN cd /var/www/html/ && chmod -R 777 var
RUN cd /var/www/html/ && chmod -R 770 pub/media
RUN cd /var/www/html/ && chmod -R 750 app/etc
RUN cd /var/www/html/ && chmod -R 770 app/etc/config.php
RUN cd /var/www/html/ && chmod u+x bin/magento

# This file will be allowed to be modified in order to run setup:upgrade
RUN cd /var/www/html/ && chmod -R 770 app/etc/env.php

# Expose SSH port
EXPOSE 22

# Execute the startup bash script on the startup
ENTRYPOINT ["/bin/bash", "/root/startup.sh"]
