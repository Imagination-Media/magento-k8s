FROM php:8.4-fpm

RUN apt-get -y update && apt-get install -y unzip vim wget curl git openssh-server cron bash-completion mariadb-client pv zip

# Install NodeJS (16)
RUN curl -sL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh && \
    apt-get install -y nodejs && \
    apt-get install -y yarn

# Copy bash config
COPY bash.bashrc /etc/bash.bashrc

#Copy magento php config file
COPY magento.ini /usr/local/etc/php/conf.d/magento.ini

# Install SSH server
RUN ssh-keygen -A
COPY sshd_config /etc/ssh/sshd_config

# Add nginx user with secure password handling
ARG NGINX_PASSWORD=dummy_password_replaced_at_build_time
RUN adduser nginx --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password && \
    echo "nginx:${NGINX_PASSWORD}" | chpasswd && \
    usermod -u 107 systemd-timesync && \
    sed -i 's/\/home\/nginx/\/var\/www\/html/g' /etc/passwd

# Copy ssh config
RUN mkdir -p /home/nginx/.ssh
COPY ssh-config.txt /home/nginx/.ssh/config
RUN chown -R nginx:nginx /home/nginx/.ssh/ && \
    chmod 600 /home/nginx/.ssh/config

# Copy the welcome message
COPY welcome.txt /etc/motd

# Copy PHP-FPM www.conf file
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

# Install PHP libraries
RUN apt-get install -y libcurl4-openssl-dev libssl-dev libicu-dev libmcrypt-dev libzip-dev zlib1g-dev libgmp-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev libxslt-dev && \
    docker-php-ext-enable opcache && \
    docker-php-ext-install calendar bcmath pdo_mysql curl ftp intl session zip gmp sockets soap xsl && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl

# Create folder to install plugins
RUN mkdir -p /usr/local/lib/php/extensions/no-debug-non-zts-20240924

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --version=2.8.6 && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer && \
    chown nginx:crontab /usr/local/bin/composer

# Install Magerun2
RUN wget -c https://files.magerun.net/n98-magerun2.phar -O n98-magerun2 && \
    mv ./n98-magerun2 /usr/local/bin/ && \
    chmod +x /usr/local/bin/n98-magerun2

#Install Patch
RUN apt-get install -y patch

#Install Grunt
RUN npm i -g grunt

#Install Magepack
RUN npm i -g magepack

#Install mage2tv cache clean
RUN mkdir -p /var/www/util && chown -R nginx:nginx /var/www/util && \
    git clone https://github.com/mage2tv/magento-cache-clean.git /var/www/util/mage2tv && \
    ln -s /var/www/util/mage2tv/bin/cache-clean.js /usr/bin/mage2tv-cache-clean && \
    chown -R nginx:nginx /usr/bin/mage2tv-cache-clean

# Mailhog
RUN apt install golang-go -y && \
    go install github.com/mailhog/MailHog@latest && \
    mv ~/go/bin/MailHog /usr/local/bin/mailhog && \
    echo "sendmail_path='/usr/local/bin/mailhog sendmail mailhog@mail.com'" > /usr/local/etc/php/conf.d/docker-php-ext-mailhog.ini

# PHP-CS
RUN curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && \
    curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar && \
    mv phpcs.phar /usr/local/bin/phpcs && \
    mv phpcbf.phar /usr/local/bin/phpcbf && \
    chmod +x /usr/local/bin/phpcs && \
    chmod +x /usr/local/bin/phpcbf && \
    chown nginx:nginx /usr/local/bin/phpcs && \
    chown nginx:nginx /usr/local/bin/phpcbf

# Install redis-cli and add custom CLI commands
RUN git clone https://github.com/lujiajing1126/redis-cli /var/www/util/redis-cli && \
    cd /var/www/util/redis-cli && npm i && npm run build && \
    chown -R nginx:nginx /var/www/util/redis-cli
COPY magupgrade.sh /usr/local/bin/magupgrade
RUN chmod +x /usr/local/bin/magupgrade && \
    chown nginx:nginx /usr/local/bin/magupgrade && \
    ln -s /var/www/util/redis-cli/bin/rdcli /usr/local/bin/redis-cli && \
    chmod +x /usr/local/bin/redis-cli && \
    chown nginx:nginx /usr/local/bin/redis-cli

# Install Sansec Magento Corediff (https://github.com/sansecio/corediff)
RUN cd /var/www/util && \
    osarch=$(uname -sm | tr 'LD ' 'ld-') && \
    curl https://sansec.io/downloads/$osarch/corediff -O && \
    chmod 755 corediff && \
    ln -s /var/www/util/corediff /usr/bin/corediff && \
    chown -R nginx:nginx /usr/bin/corediff

# Expose SSH port
EXPOSE 22

# Execute the startup bash script on the startup
COPY startup.sh /root/startup.sh
ENTRYPOINT ["/bin/bash", "/root/startup.sh"]
