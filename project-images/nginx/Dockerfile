FROM ghcr.io/imagination-media/magento-k8s/nginx:latest
#FROM ghcr.io/imagination-media/magento-k8s/nginx:latest-gcsfuse

ARG APP_ETC_ENV

# Copy repository
COPY repository.zip /var/www/html/
RUN unzip -q /var/www/html/repository.zip -d /var/www/html
RUN rm -rf /var/www/html/repository.zip

# Create app/etc/env.php from environment variable
RUN mkdir -p /var/www/html/app/etc
RUN rm -rf /var/www/html/app/etc/env.php
RUN echo "$APP_ETC_ENV" | base64 --decode > /var/www/html/app/etc/env.php

# Set the permissions for the Magento directory
RUN cd /var/www/ && chown -R root:nginx html && chmod -R 750 html
RUN cd /var/www/html/ && chmod -R 770 generated
RUN cd /var/www/html/ && chmod -R 775 var
RUN cd /var/www/html/ && chmod -R 770 pub/media
RUN cd /var/www/html/ && chmod -R 750 app/etc/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
