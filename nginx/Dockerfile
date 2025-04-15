FROM nginx:1.23.2

WORKDIR /var/www/html

# Install git
RUN apt-get update
RUN apt-get install -y git vim zip

#Copy Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Execute the startup bash script on the startup
COPY startup.sh /docker-entrypoint.d/00-nginx-conf-mod.sh
RUN chmod 755 /docker-entrypoint.d/00-nginx-conf-mod.sh
RUN chmod +x /docker-entrypoint.d/00-nginx-conf-mod.sh

# Install Python 3
RUN apt-get update
RUN apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev -y
RUN curl -O https://www.python.org/ftp/python/3.9.1/Python-3.9.1.tgz
RUN tar -xf Python-3.9.1.tgz
RUN cd /var/www/html/Python-3.9.1 && ./configure --enable-optimizations
RUN cd /var/www/html/Python-3.9.1 && make -j 2
RUN cd /var/www/html/Python-3.9.1 && make altinstall
RUN cd /var/www/html/ && rm -rf /var/www/html/Python-3.9.1 && rm -rf /var/www/html/Python-3.9.1.tgz

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
