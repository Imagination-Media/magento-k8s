FROM ghcr.io/imagination-media/magento-k8s/php-fpm:8.1

# Install grpc
RUN apt-get install autoconf -y
RUN apt-get install zlib1g-dev -y
RUN wget http://pear.php.net/go-pear.phar
RUN php go-pear.phar && pecl install grpc
RUN rm -rf go-pear.phar
RUN docker-php-ext-enable grpc
