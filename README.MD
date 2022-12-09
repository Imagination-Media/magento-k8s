<p align="center">
<img alt="commercetools logo" src="https://cdn.softwarereviews.com/production/logos/offerings/1202/large/AdobeCommerce1.png?1657041673" width="224px"/>
</p>
<h2 align="center">
  Magento 2 Kubernetes Infrastructure
</h2>

<h4 align="center">Magento 2 deployed with Kubernetes splitting the cron, admin panel, and storefront in different instances.</h4>

<p align="center" width="100%">
<img alt="Docker logo" src="https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png" width="15%" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img alt="Kubernetes logo" src="https://foghornconsulting.com/wp-content/uploads/2022/01/kubernetes-1.png" width="21%" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img alt="Magento logo" src="https://seeklogo.com/images/M/magento-logo-7F3911AE9E-seeklogo.com.png" width="12%" />
</p>

<p align="center">Deploy a <b>Kubernetes</b> production (or development) infrastructure for a <b>Adobe Commerce (Magento)</b> store. This infrastructure is <b> ready to scale up and down as needed</b>, and suits any store size, from a small merchant to an enterprise one. These scripts and images were <b>created based on the official PHP, Nginx, Redis images</b>, optimized and configured to offer a complete infrastructure for a Magento 2 website.</p>

<p align="center"><img src="https://img.shields.io/badge/Language-YAML-bluegreen" />&nbsp;<img src="https://img.shields.io/badge/Framework-Kubernetes-blue"/>&nbsp;<img src="https://img.shields.io/badge/Cloud%20Provider-Google%20Cloud-9cf" />&nbsp;<img src="https://img.shields.io/badge/Cloud%20Provider-AWS-orange" />&nbsp;<img src="https://img.shields.io/badge/Cloud%20Provider-Azure-blue" />&nbsp;<img src="https://img.shields.io/badge/Created%20By-IMDigital-orange" /></p>

<br/>

# Infrastructure
The infrastructure for a Magento 2 website is made of the services required by the application such as the database, Redis for sessions, RabbitMQ for asynchronous jobs, etc.

Then, we have NGINX & PHP-FPM instances that are going to serve the website.

To determine what version of PHP, RabbitMQ, Redis, and database to use, please check the official [Adobe Commerce documentation](https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/system-requirements.html). Versions may vary depending on the Adobe Commerce version the store is running.

<img src="https://lucid.app/publicSegments/view/aa1f2018-8849-46e9-95ae-191cc4e8f726/image.png" alt="Infrastructure diagram" />

## File permissions & server access
As an approach to maintain security and integrity across all the servers, the code base in the server is read-only, meaning SSH users can't modify anything except the pub/media and the var directories. This also prevents issues related to auto-scale and the codebase shared accross the different node pools (frontend, admin, and cron).

Root access isn't allowed for SSH users. No one can login as root on the application servers.

No instance is exposed to the internet through SSH, except the admin panel PHP-FPM pod. That's the only one instance users can SSH and check the code base.

<img src="https://github.com/Imagination-Media/magento-k8s/blob/master/screenshots/ssh-delete.png" alt="Error when trying to delete vendor directory" />
<p align="center">
Access denied error when trying to delete files
</p>

## Services

<p align="left" width="100%">
<img src="https://upload.wikimedia.org/wikipedia/en/thumb/9/97/Elastic_NV_logo.svg/1200px-Elastic_NV_logo.svg.png" width="30%" alt="Elasticsearch Logo" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src="https://download.logo.wine/logo/Redis/Redis-Logo.wine.png" width="30%" alt="Redis Logo" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/RabbitMQ_logo.svg/2560px-RabbitMQ_logo.svg.png" width="20%" alt="RabbitMQ Logo" />
</p>

These are the services required by Magento to execute. We use the official docker images, and the version of each service may vary depending on the Adobe Commerce version.
- [RabbitMQ](https://hub.docker.com/_/rabbitmq)
- [Redis](https://hub.docker.com/_/redis)
- [ElasticSearch](https://hub.docker.com/_/elasticsearch)

These services aren't exposed to the internet. They are only available inside the cluster.

## Database

<p align="left" width="100%">
<img src="https://mariadb.com/wp-content/uploads/2019/11/mariadb-logo-vert_blue-transparent.png" width="10%" alt="MariaDB Logo" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src="https://download.logo.wine/logo/MySQL/MySQL-Logo.wine.png" width="18%" alt="MySQL Logo" />
</p>

For the database, we always recommend using a database service offered by your cloud provider. Their services always come with backup routines and read/write replicas, and they can easily scale up and down the database instances for you. In that way, you don't need to manually manage all of that.

For the database we always recommend to use [MariaDB](https://hub.docker.com/_/mariadb) instead of [MySQL](https://hub.docker.com/_/mysql) as it has some improvements and performs a little bit better when compared to MySQL. But both versions are supported by our infrastructure.

## Application
The Magento application mainly consists on two services, the webserver [NGINX](https://www.nginx.com/), and [PHP-FPM](https://www.php.net/manual/en/install.fpm.php).

Our infrastructure will (for production apps) split the application into three different node pools. One will host Nginx & Php-fpm pods for the storefront traffic, one will host Nginx & Php-fpm pods for the admin traffic, and one will host one Php-fpm pod for the Magento cron. In that way, we dedicate resources to each one of these node pools to serve their traffic, the cron pod is never scaled up to prevent duplicated cron jobs, and the admin panel can be restricted only to specific IP addresses and also never scaled up.

For development environments, we can have just one node pool for all three services, but for production, it's highly recommended to split them.

<img src="https://github.com/Imagination-Media/magento-k8s/blob/master/screenshots/node-pools.png" alt="Node Pools" />

## Proxy

<img src="https://seeklogo.com/images/E/envoy-proxy-logo-AA21B06AE5-seeklogo.com.png" width="60px" alt="Envoy logo" />

We use [Envoy Contour](https://projectcontour.io/) as the load balancer and proxy for the application.

[Envoy](https://www.envoyproxy.io/) was created by [Lyft's](https://www.lyft.com/) team to solve issues and attend requirements they had that weren't possible to attend/solve with other solutions like NGINX and HAProxy.

With Envoy we route the traffic to the admin and storefront instances, and it's used as the load balancer instead of the default load balancer offered by the cloud providers.

To set up Envoy we run the https://github.com/Imagination-Media/magento-k8s/scripts/ingress/production/21-contour.yaml script.

Then, we use https://github.com/Imagination-Media/magento-k8s/scripts/ingress/production/23-ingress.yaml to define the domains that are going to be managed by Envoy and what k8s service is going to be used to serve each one of them.

## SSL Certificates

<img src="https://seeklogo.com/images/L/let-s-encrypt-logo-DF90D21CBA-seeklogo.com.png" alt="Let's Encrypt logo" width="90px" />

Our Kubernetes infrastructure uses [cert-manager](https://github.com/cert-manager/cert-manager) to generate and manage SSL certificates.

With that, we can generate and renew [Let's Encrypt](https://letsencrypt.org/) certificates whenever needed.

To start the cert manager service we use the https://github.com/Imagination-Media/magento-k8s/scripts/ingress/production/22.1-cert-manager.yaml script.

Then, we use https://github.com/Imagination-Media/magento-k8s/scripts/ingress/production/22.2-lets-encrypt.yaml to create the certificate issuer.

And finally, https://github.com/Imagination-Media/magento-k8s/scripts/ingress/production/22.3-domains.yaml to define the certificates that are going to be generated and maintained.

## SSH
The only instance (pod) exposed to the internet and that accepts SSH connections is the admin panel pod. As all of the pods are read-only pods, the SSH user can access and modify some directories, but the code base can't be modified.

All SSH connections are managed through SSH keys. So, in order to give SSH access to a developer we must add their private key to the authorized keys. Please, read the GitHub Secrets section to know more about this.

This is the welcome message when SSHing the admin pod:

<img src="https://github.com/Imagination-Media/magento-k8s/blob/master/screenshots/ssh-welcome.png" alt="SSH welcome message" />


# Custom Images
We developed two custom images, one for NGINX and one for PHP-FPM. These images have all the required plugins, configuration, and optimization for Magento 2 websites, so all the infrastructure deployed by our solution was created based on these two images along with images for other services.

## PHP-FPM

<img src="https://cdn-icons-png.flaticon.com/512/5968/5968332.png" width="60px" alt="Php Logo" />

The Php-Fpm image was created based on the official [Php-Fpm image](https://hub.docker.com/_/php).

Our image has installed all the PHP [extensions/libraries required by Magento](https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/prerequisites/php-settings.html.). We also optimized the PHP-FPM configuration, adjusted server permissions, installed the cron, customized the SSH welcome message, and installed tools such as [n98-magerun](https://github.com/netz98/n98-magerun2 "n98-magerun") and [grunt](https://gruntjs.com/) to help us to develop and maintain the Magento code base inside the container.

The dockerfiles for each PHP version are available inside https://github.com/Imagination-Media/magento-k8s/tree/master/php-fpm.

We currently have images for:
- [7.4](https://github.com/Imagination-Media/magento-k8s/tree/master/php-fpm/7.4)
- [8.1](https://github.com/Imagination-Media/magento-k8s/tree/master/php-fpm/8.1)

## NGINX
<img src="https://destatic.blob.core.windows.net/images/nginx.png" width="40px" alt="Nginx Logo" />

The NGINX image was created based on the official [NGINX image](https://hub.docker.com/_/nginx). We are using the version [1.23.2](https://hub.docker.com/layers/library/nginx/1.23.2/images/sha256-d5e4095bb4bcd2c40d6aba552f9ea66aacb1d0a5137a521dc6b0503b40b08921?context=explore).

We customized the NGINX configuration to use the PHP-FPM container to execute any PHP code, it also uses different domains for the storefront and the admin panel, it has config fields that allow us to restrict IPs to access the storefront and the admin panel.

The NGINX dockerfile and NGINX config files are available in https://github.com/Imagination-Media/magento-k8s/tree/master/nginx.

## Gcsfuse
<img src="https://help.sap.com/doc/8b8d6fffe113457094a17701f63e3d6a/GIGYA/en-US/loio41289de270b21014bbc5a10ce4041860_LowRes.png" width="60px" alt="Google Cloud Storage logo" />

Google Cloud has a storage solution called [Cloud Storage](https://cloud.google.com/storage/). It's cheap, and for dev environments it's a good solution. In order to use it we had to install and configure [gcsfuse](https://github.com/GoogleCloudPlatform/gcsfuse) and release a new image tag with it. So, if you want to use it make sure you are using the images with the <b>gcsfuse</b> tag (Nginx & Php-Fpm images).

## Shared directories
Shared directories are the directories that should be mounted as volumes across all the Nginx and Php-Fpm pods. They have files that are managed by the application.

These directories are going to be:
- **pub/media** - It's the directory where Magento stores the catalog, cms and any other images.
- **var/log** - The Magento logs.
- **var/report** - The Magento error reports.
- **var/export** - The Magento exported files from export profiles.
- **var/importexport** - Files to imported into import profiles.

Everything else, except the subdirectories inside the var directory are read only. SSH users can't modify any file or directory.

# Using the template
The following topics are going to describe how to set up a Kubernetes infrastructure using this template and automating it with your GitHub repository.

## Creating base structure
In your Github Magento code base, please create this directory structure:

    ├── codebase
    │   ├── server
    │   ├──├── docker
    │   ├──├──├──nginx
    │   ├──├──├──phpfpm
    │   ├──├── k8s


The **docker** directory will host our custom images for our Magento project, and **k8s** will host the Kubernetes scripts used to set up the infrastructure.

## Setting up images
First we need to use setup two images, one for Nginx & Php-Fpm. They are going to be created based on our [base images](https://github.com/Imagination-Media/magento-k8s#custom-images "base images"). These images are going to have the Magento code base, the compiled static content and the PHP scripts.

### Nginx
Inside the **nginx** directory, please create a **Dockerfile** file with this content:
```yaml
FROM ghcr.io/imagination-media/magento-k8s/nginx:latest

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
```

The first line defines the image we are going to use for our NGINX image. We must use **ghcr.io/imagination-media/magento-k8s/nginx:latest** by default, or use  **ghcr.io/imagination-media/magento-k8s/nginx:latest-gcsfguse** if using [gcsfuse](ghcr.io/imagination-media/magento-k8s/nginx:latest "gcsfuse").

This image will download the repository, install composer packages, deploy the static content files, and then compile the PHP code.

The name of our image will be **ghcr.io/my-company/my-repository/nginx:myenvironment**. So, we will be generating images for each environment and use different tags for each one of these environments.

### Php-Fpm
Inside the **phpfpm** directory, please create a **Dockerfile** file with this content:

```yaml
FROM ghcr.io/imagination-media/magento-k8s/php-fpm:8.1

ARG SSH_AUTHORIZED_KEYS
ARG SSH_ID_RSA_PRIVATE
ARG SSH_ID_RSA_PUBLIC
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
```

The first line defines the image we are going to use for our Php-Fpm image. We have different images for each PHP version, and on each version we also have a [gcsfuse version](The first line defines the image we are going to use for our NGINX image. We must use **ghcr.io/imagination-media/magento-k8s/nginx:latest** by default, or use  **ghcr.io/imagination-media/magento-k8s/nginx:latest-gcsfguse** if using [gcsfuse](ghcr.io/imagination-media/magento-k8s/nginx:latest "gcsfuse") of it. So we have for example **ghcr.io/imagination-media/magento-k8s/php-fpm:8.1-gcsfuse** for PHP 8.1, and **ghcr.io/imagination-media/magento-k8s/php-fpm:8.1-gcsfuse** for PHP 8.1 with gcsfuse. To know more about the support versions please check https://github.com/Imagination-Media/magento-k8s#php-fpm.

This image will download the repository, install composer packages, deploy the static content files, and then compile the PHP code.

The name of our image will be **ghcr.io/my-company/my-repository/php-fpm:myenvironment**. So, we will be generating images for each environment and use different tags for each one of these environments.

## K8s Files

## GitHub configuration
### Actions
### Environments
### Secrets

# Customizing images
