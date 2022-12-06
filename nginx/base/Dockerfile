FROM nginx:1.23.2

# Install git
RUN apt-get update
RUN apt-get install -y git vim zip

#Copy Nginx config
COPY nginx.conf /etc/nginx/nginx.conf
COPY magento.conf /etc/nginx/magento.conf

# Execute the startup bash script on the startup
COPY startup.sh /docker-entrypoint.d/00-nginx-conf-mod.sh
RUN chmod 755 /docker-entrypoint.d/00-nginx-conf-mod.sh
RUN chmod +x /docker-entrypoint.d/00-nginx-conf-mod.sh

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
