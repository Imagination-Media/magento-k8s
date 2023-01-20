FROM php:8.1-fpm

RUN apt-get -y update
RUN apt-get install -y unzip
RUN apt-get install -y vim
RUN apt-get install -y wget
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y openssh-server
RUN apt-get install -y cron
RUN apt-get install -y bash-completion
RUN apt-get install -y mariadb-client
RUN apt-get install -y pv

# Install NodeJS (16)
RUN curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt-get install -y nodejs
RUN apt-get install -y yarn

# Copy bash config
COPY bash.bashrc /etc/bash.bashrc

#Copy magento php config file
COPY magento.ini /usr/local/etc/php/conf.d/magento.ini

# Install SSH server
RUN ssh-keygen -A
COPY sshd_config /etc/ssh/sshd_config

# Add nginx user
RUN adduser nginx --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
RUN echo "nginx:123456" | chpasswd
RUN usermod -u 107 systemd-timesync

# Change default nginx path when SSHing
RUN sed -i 's/\/home\/nginx/\/var\/www\/html/g' /etc/passwd

# Copy ssh config
RUN mkdir -p /home/nginx/.ssh
COPY ssh-config.txt /home/nginx/.ssh/config
RUN chown -R nginx:nginx /home/nginx/.ssh/
RUN chmod 600 /home/nginx/.ssh/config

# Copy the welcome message
COPY welcome.txt /etc/motd

# Copy PHP-FPM www.conf file
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

# Install PHP libraries
RUN docker-php-ext-enable opcache
RUN docker-php-ext-install calendar
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install pdo_mysql
RUN apt-get install -y \
        libcurl4-openssl-dev \
    && docker-php-ext-install curl

RUN apt-get install -y \
        libssl-dev \
    && docker-php-ext-install ftp phar

RUN apt-get install -y \
        libicu-dev \
    && docker-php-ext-install intl

RUN apt-get install -y \
        libmcrypt-dev \
    && docker-php-ext-install session

RUN apt-get install -y \
        libzip-dev \
        zlib1g-dev \
    && docker-php-ext-install zip

RUN apt-get install -y \
        libgmp-dev \
    && docker-php-ext-install gmp

RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

RUN apt-get install -y libmagickwand-dev
RUN pecl install imagick && docker-php-ext-enable imagick

RUN apt-get install -y libxslt-dev
RUN docker-php-ext-install soap
RUN docker-php-ext-install xsl
RUN docker-php-ext-install sockets
RUN docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl

# Create folder to install plugins
RUN mkdir -p /usr/local/lib/php/extensions/no-debug-non-zts-20190902

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --version=2.2.18
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer
RUN chown nginx:crontab /usr/local/bin/composer

# Install Magerun2
RUN wget -c https://files.magerun.net/n98-magerun2.phar -O n98-magerun2
RUN mv ./n98-magerun2 /usr/local/bin/
RUN chmod +x /usr/local/bin/n98-magerun2

#Install Patch
RUN apt-get install -y patch

#Install Grunt
RUN npm i -g grunt

#Install mage2tv cache clean
RUN mkdir -p /var/www/util && chown -R nginx:nginx /var/www/util
RUN git clone https://github.com/mage2tv/magento-cache-clean.git /var/www/util/mage2tv
RUN ln -s /var/www/util/mage2tv/bin/cache-clean.js /usr/bin/mage2tv-cache-clean
RUN chown -R nginx:nginx /usr/bin/mage2tv-cache-clean

# Expose SSH port
EXPOSE 22

# Execute the startup bash script on the startup
COPY startup.sh /root/startup.sh
ENTRYPOINT ["/bin/bash", "/root/startup.sh"]
