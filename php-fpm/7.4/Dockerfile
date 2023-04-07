FROM php:7.4-fpm

RUN apt-get -y update && apt-get install -y unzip vim wget curl git openssh-server cron bash-completion mariadb-client pv zip

# Install NodeJS (16)
RUN curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh && \
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

# Add nginx user
RUN adduser nginx --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password && \
    echo "nginx:123456" | chpasswd && \
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
RUN docker-php-ext-enable opcache && \
    docker-php-ext-install calendar && \
    docker-php-ext-install bcmath && \
    docker-php-ext-install pdo_mysql && \
    apt-get install -y \
    libcurl4-openssl-dev \
    && docker-php-ext-install curl && \
    apt-get install -y \
    libssl-dev \
    && docker-php-ext-install ftp phar && \
    apt-get install -y \
    libicu-dev \
    && docker-php-ext-install intl && \
    apt-get install -y \
    libmcrypt-dev \
    && docker-php-ext-install session && \
    apt-get install -y \
    libzip-dev \
    zlib1g-dev \
    && docker-php-ext-install zip && \
    apt-get install -y \
    libgmp-dev \
    && docker-php-ext-install gmp && \
    apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd && \
    apt-get install -y libmagickwand-dev && \
    pecl install imagick && docker-php-ext-enable imagick && \
    apt-get install -y libxslt-dev && \
    docker-php-ext-install soap && \
    docker-php-ext-install xsl && \
    docker-php-ext-install sockets && \
    docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl

# Create folder to install plugins
RUN mkdir -p /usr/local/lib/php/extensions/no-debug-non-zts-20190902

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --version=2.2.18 && \
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
    go get github.com/mailhog/MailHog && \
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

# Install Golang
RUN arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \
    curl -O https://dl.google.com/go/go1.19.3.linux-${arch}.tar.gz && \
    tar xvf go1.19.3.linux-${arch}.tar.gz && \
    chown -R root:root ./go && \
    mv go /usr/local && \
    rm -rf go1.19.3.linux-${arch}.tar.gz
ENV GOPATH=$HOME/work
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Google Cloud SDK
RUN apt-get install apt-transport-https ca-certificates gnupg -y && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install kmod -y && \
    apt-get install google-cloud-cli -y

# Install gcsfuse
RUN apt-get install fuse -y && \
    /usr/local/go/bin/go install github.com/googlecloudplatform/gcsfuse@latest

# Install grpc
RUN apt-get install autoconf -y && \
    apt-get install zlib1g-dev -y && \
    wget http://pear.php.net/go-pear.phar && \
    php go-pear.phar && pecl install grpc && \
    rm -rf go-pear.phar && \
    docker-php-ext-enable grpc

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
