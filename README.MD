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

<img src="https://github.com/Imagination-Media/magento-k8s/blob/master/screenshots/services.png" alt="Node Pools" />

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

To set up Envoy we run the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/21-contour.yaml script.

Then, we use https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/23-ingress.yaml to define the domains that are going to be managed by Envoy and what k8s service is going to be used to serve each one of them.

## SSL Certificates

<img src="https://seeklogo.com/images/L/let-s-encrypt-logo-DF90D21CBA-seeklogo.com.png" alt="Let's Encrypt logo" width="90px" />

Our Kubernetes infrastructure uses [cert-manager](https://github.com/cert-manager/cert-manager) to generate and manage SSL certificates.

With that, we can generate and renew [Let's Encrypt](https://letsencrypt.org/) certificates whenever needed.

To start the cert manager service we use the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/22.1-cert-manager.yaml script.

Then, we use https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/22.2-lets-encrypt.yaml to create the certificate issuer.

And finally, https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/22.3-domains.yaml to define the certificates that are going to be generated and maintained.

## SSH
The only instance (pod) exposed to the internet and that accepts SSH connections is the admin panel pod. As all of the pods are read-only pods, the SSH user can access and modify some directories, but the code base can't be modified.

All SSH connections are managed through SSH keys. So, in order to give SSH access to a developer we must add their private key to the authorized keys. Please, read the GitHub Secrets section to know more about this.

This is the welcome message when SSHing the admin pod:

<img src="https://github.com/Imagination-Media/magento-k8s/blob/master/screenshots/ssh-welcome.png" alt="SSH welcome message" />

<hr/>

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
<img src="https://www.intelligencepartner.com/wp-content/uploads/2017/05/CloudStorage-4.png" width="60px" alt="Google Cloud Storage logo" />

Google Cloud has a storage solution called [Cloud Storage](https://cloud.google.com/storage/). It's cheap, and for dev environments it's a good solution.

## Shared directories
Shared directories are the directories that should be mounted as volumes across all the Nginx and Php-Fpm pods. They have files that are managed by the application.

These directories are going to be:
- **pub/media** - It's the directory where Magento stores the catalog, cms and any other images.
- **var/log** - The Magento logs.
- **var/report** - The Magento error reports.
- **var/export** - The Magento exported files from export profiles.
- **var/importexport** - Files to imported into import profiles.

Everything else, except the subdirectories inside the var directory are read only. SSH users can't modify any file or directory.

<hr/>

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

The first line defines the image we are going to use for our NGINX image. We must use **ghcr.io/imagination-media/magento-k8s/nginx:latest** by default.

This image will download the repository, install composer packages, deploy the static content files, and then compile the PHP code.

The name of our image will be **ghcr.io/my-company/my-repository/nginx:myenvironment**. So, we will be generating images for each environment and use different tags for each one of these environments.

### Php-Fpm
Inside the **phpfpm** directory, please create a **Dockerfile** file with this content:

```yaml
FROM ghcr.io/imagination-media/magento-k8s/php-fpm:8.1

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
```

The first line defines the image we are going to use for our Php-Fpm image.

This image will download the repository, install composer packages, deploy the static content files, and then compile the PHP code.

The name of our image will be **ghcr.io/my-company/my-repository/php-fpm:myenvironment**. So, we will be generating images for each environment and use different tags for each one of these environments.

### app/etc/config.php
In order to execute the di:compile and static deployment commands, we need to add the website scope configuration to the app/etc/config.php file. We can do that by running **bin/magento app:config:dump scopes**.

## K8S Files
On this section we are going to describe the scripts involved on this infrastructure, what each script is used for, and how to deploy them.

All the Kubernetes scripts are inside the https://github.com/Imagination-Media/magento-k8s/tree/master/scripts folder.

### Namespace
The namespace as the name suggests, it's a namespace, or in other words, an isolated environment where things get deployed. For your project, we suggest having a different namespace per environment if they are going to share the same Kubernetes cluster.

So the first script we must run is https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/1-namespace.yaml.

```ssh
kubectl apply -f=scripts/1-namespace.yaml
```

### Configmap
[Configmaps](https://kubernetes.io/docs/concepts/configuration/configmap/ "Configmaps") are values that are going to be used as environment variables in our pods. Our images require a couple of values to be set, to define things like the crontab if we run or not setup:upgrade, if we enable or not SSH, etc.

In the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/2-configmap.yaml file, we create these configmaps for all of our application pods. So, we have different configmaps for the NGINX and PHP-FPM pods for the admin, for the storefront, and also for the cron.

- **admin-configmap-phpfpm** - PHP-FPM admin panel configmap.
- **admin-configmap-nginx** - NGINX admin panel configmap.
- **cron-configmap-phpfpm** - PHP-FPM cron configmap.
- **front-configmap-phpfpm** - PHP-FPM storefront configmap.
- **front-configmap-phpfpm** - PHP-FPM storefront configmap.

These are the required values required by each configmap type:
#### PHP-FPM
- **setup_upgrade** - Set 1 or 0 to define if we will run the setup:upgrade command during the pod stand-up. If this option is set to 1, the pod will run setup:upgrade, di:compile, and then deploy:static:content.
- **magento_static_content_jobs** - number of simultaneous jobs that are going to run when running the deploy static content command. This option is only used if the **setup_upgrade** option was set to 1.
- **environment_name** - This variable is just used to help us to identify what environment is this environment,
- **enable_ssh** - This option accepts 1 or 0 as the value, and it's used to define if we will initialize the SSH service or not for this pod.
- **cron_jobs** - This variable expects a base64 encoded value with the crontab configuration. This variable is mainly used by the cron PHP-FPM pod, to execute the Magento cron. So, we will always have here the Magento cron job along with any other cron job you may need to execute in your application. To have the Magento cron, we will have something like this as the original value:

```cron
* * * * * php /var/www/html/bin/magento cron:run > /var/www/html/var/log/cron.log
```

And then, the base64 value will be:
```
KiAqICogKiAqIHBocCAvdmFyL3d3dy9odG1sL2Jpbi9tYWdlbnRvIGNyb246cnVuID4gL3Zhci93d3cvaHRtbC92YXIvbG9nL2Nyb24ubG9nCg==
```

#### NGINX
- **admin_domain** - The domain where the Magento admin panel is going to be served. For example, ***admin-magento-open-source.imaginationmedia.com***.
- **frontend_domain** - The domain where the Magento storefront is going to be served. For example, ***admin-magento-open-source.imaginationmedia.com***.
- **admin_store** - Store code used by the admin store in Magento. By default, it's always ***admin***.
- **frontend_store** - Store code used by the storefront store in Magento. For example, ***store1***.
- **magento_mode** - Accepts the values 1 or 0, and it's used to define if Magento is running in production mode.
- **php_fpm_service** - This is the variable where we define what the PHP-FPM service NGINX is going to use to process any PHP file. As we consistently deployed a PHP-FPM pod along with an NGINX pod, NGINX is just the web server, and any PHP code will be PHP-FPM's pod responsibility. So, on this variable, we will have something like ***magento-admin-phpfpm-service.magento-demo-production:9001*** as the value. It's the name of the service + the namespace + the port. The port will always be ***9001***, but the name of the service and the namespace may vary depending on your configuration.
- **ip_addresses** - This is an optional value that can be used to restrict the IP addresses that are allowed to access the storefront. This is useful for development environments, blocking access from out of our team.
- **admin_ip_addresses** - This is an optional value that can be used to restrict the IP addresses that are allowed to access the admin panel. This is a good practice for development and production environments, restricting access from out of our team.

#### Gcsfuse
If you are using gcsfuse to mount the volumes, you will also need to set up a couple of extra variables.

You first need to generate a service account key from your GCP project, which will be used to mount the Cloud Storage volumes.

Once you have the service account key, these are the variables we are going to set up:

- **gcsfuse_enable** - Set it with 1 to enable gcsfuse.
- **gke_email** - The service account key email address.
- **gke_service_account_key** - The base64 encoded service account key.
- **gke_bucket_var_export** - The name of your Cloud storage bucket to mount the ***var/export*** directory.
- **gke_bucket_var_report** - The name of your Cloud storage bucket to mount the ***var/report*** directory.
- **gke_bucket_var_importexport** - The name of your Cloud storage bucket to mount the ***var/importexport*** directory.
- **gke_bucket_var_log** - The name of your Cloud storage bucket to mount the ***var/log*** directory.
- **gke_bucket_pub_media** - The name of your Cloud storage bucket to mount the ***pub/media*** directory.

### Services
These are the scripts responsible to stand-up the services used by Magento.
#### Redis for FPC (Full Page Cache)
Redis is going to be used as the service to store the Magento Full Page Cache, and we deploy it using the scripts https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/3-redis-fpc-deployment.yaml and https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/6-redis-fpc-service.yaml.

```ssh
kubectl apply -f=scripts/3-redis-fpc-deployment.yaml
kubectl apply -f=scripts/6-redis-fpc-service.yaml
```

#### Elasticsearch
Magento uses [ElasticSearch](https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/prerequisites/search-engine/overview.html "ElasticSearch") to index search results, layered navigation filters, etc.

To deploy ElasticSearch we use the scripts https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/4-elasticsearch-deployment.yaml and https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/7-elasticsearch-service.yaml.

```ssh
kubectl apply -f=scripts/4-elasticsearch-deployment.yaml
kubectl apply -f=scripts/7-elasticsearch-service.yaml
```

#### RabbitMQ
Magento uses [RabbitMQ](https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/prerequisites/rabbitmq.html "RabbitMQ") for asynchronous jobs.

To deploy RabbitMQ we use the scripts https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/5-rabbitmq-deployment.yaml and https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/8-rabbitmq-service.yaml.

```ssh
kubectl apply -f=scripts/5-rabbitmq-deployment.yaml
kubectl apply -f=scripts/8-rabbitmq-service.yaml
```

#### Redis Sessions
We use Redis for the customer and admin sessions. Redis has a better performance when compared to session files, and also when compared to database sessions.

We can use one of the AWS, GPC, Azure services to spin up a Redis instance for sessions, because they are data we can't lose in case of a pod restart, they should be a persistent volume.

But in case you also want to deploy it as a Kubernetes pod we can use the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/9-session/9-redis-sessions.yaml script.

```ssh
kubectl apply -f=scripts/9-session/9-redis-sessions.yaml
```

### Image Secret
We use [GitHub's container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry "GitHub's container registry") service to generate and store container images. And as our repositories are private, only authenticated users can access them and download these images.

Kubernetes has [this guide](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ "this guide") that explains how to pull images from a private registry.

Once we generate the token we can have an image script like https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/17-image-secret.yaml.

### Database
If you are running a development environment you can deploy a database pod within a Kubernetes service using the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/10-database/10-database.yaml script as an example.

The database name will be ***magento***, the password for the root user is going to be ***root***, and to access the database the host will be ***database-service.my-namespace-name*** on the port 33006.

***For production environments please use of the one services provided by your cloud provider, like Cloud SQL (GCP), RDS (AWS), etc. These services provide multi-cluster environments that perform a lot better than compared to a single pod database, they also manage backups, etc.***

### Ingress
As the Magento application has to exposed to the internet (the admin and the storefront), we must have a [Kubernetes ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/ "Kubernetes ingress") to expose the services. On https://kubernetes.io/docs/concepts/services-networking/ingress/ we described our strategy to proxy this application, and to deploy the ingress service and its configuration we use the directories inside https://github.com/Imagination-Media/magento-k8s/tree/master/scripts/21-ingress.

We have two directories there, **local** and **production**. One, to be used for local environments. and the other one for production environments.

#### Cert Manager
Before deploying Envoy as the proxy/load balancer/ingress, we must deploy the cert manager service, responsible to be a service that generates SSL certificates.

We use the script https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/22.1-cert-manager.yaml to deploy the cert manager service.

```ssh
kubectl apply -f=scripts/21-ingress/production/22.1-cert-manager.yaml
```

#### SSL
To start the SSL management service, we also need to define who owns the SSL certificates. For that we need to deploy a [ClusterIssuer](https://cert-manager.io/docs/concepts/issuer/ "ClusterIssuer").

We can deploy it running the script https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/22.2-lets-encrypt.yaml.

On **email: info@imaginationmedia.com** you define the email address of who owns the SSL certificates.

Then, we have the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/22.3-domains.yaml script where we define the SSL certificates that are going to be generated, and what's the domain used on each one of them.

```ssh
kubectl apply -f=scripts/21-ingress/production/22.2-lets-encrypt.yaml
kubectl apply -f=scripts/21-ingress/production/22.3-domains.yaml
```

#### Envoy
To deploy [Envoy Contour](https://projectcontour.io/ "Envoy Contour"), we have the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/21-contour.yaml script.

Once Envoy is deployed we can configure the routes that are going to be managed by Envoy. So, we define the domains that attached to the Kubernetes services. We have the script https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-ingress/production/23-ingress.yaml where we define all of that.

```ssh
kubectl apply -f=scripts/21-ingress/production/21-contour.yaml
kubectl apply -f=scripts/21-ingress/production/23-ingress.yaml
```

### Admin
The admin panel will be deployed with one PHP-FPM pod, and one NGINX pod. The PHP-FPM pod will be exposed to the internet for SSH connections (enable_ssh is set to 1 on the admin-configmap-phpfpm configmap). The magento setup:upgrade command will also be executed on the PHP-FPM pod, so any database change, upgrade, downgrade will be performed by this pod (setup_upgrade is set to 1 on the admin-configmap-phpfpm configmap).

Admin pods aren't scaled up, they are single instances.

To deploy the PHP-FPM and the NGINX pods we use the scripts https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/18.1-magento-admin-phpfpm.yaml and https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/18.2-magento-admin-nginx.yaml.

```ssh
kubectl apply -f=scripts/18.1-magento-admin-phpfpm.yaml
kubectl apply -f=scripts/18.2-magento-admin-nginx.yaml
```

### Cron
For the cron we deploy a single PHP-FPM cron pod, and this pod won't be scaled up. As the cron doesn't serve any HTTP/HTTPS traffic there's no need to have an NGINX pod.

The script we can use to deploy the cron pod is https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/19-magento-cron-phpfpm.yaml.

```ssh
kubectl apply -f=scripts/19-magento-cron-phpfpm.yaml
```

### Storefront
The storefront will be deployed with one PHP-FPM pod, and one NGINX pod.
The scripts used to deploy it are https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/20.1-magento-front-phpfpm.yaml and https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/20.2-magento-front-nginx.yaml.

Storefront pods are scaled up and down according to the resources usage. To scale up and down the NGINX and the PHP-FPM instances we use [HorizontalPodAutoscaler scripts.](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ "HorizontalPodAutoscaler scripts.")

We have https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/20.3-magento-front-phpfpm-hpa.yaml to scale up and down the PHP-FPM pods, and https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/20.4-magento-front-phpfpm-nginx.yaml for NGINX.

```ssh
kubectl apply -f=scripts/20.1-magento-front-phpfpm.yaml
kubectl apply -f=scripts/20.2-magento-front-nginx.yaml
kubectl apply -f=scripts/20.3-magento-front-phpfpm-hpa.yaml
kubectl apply -f=scripts/20.4-magento-front-phpfpm-hpa.yaml
```

### Clean Nodes
We have the https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/21-clean-nodes-cron.yaml script which deploys our https://github.com/Imagination-Media/gcp-kubernetes-clean-nodes script (only for Google Cloud projects) which is used to clean up any temporary data and files from Kubernetes nodes.

### Using the services
To use the Redis, ElasticSearch, RabbitMQ and any service deployed by our Kubernetes scripts we always use as the host the name of the service + the namespace.

For example, for Redis FPC we use ***redis-fpc-service.magento-demo-production***.

For ElasticSearch we use ***elasticsearch-service.magento-demo-production***.

### Node pools
[A node poo](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools "A node poo")l is a group of nodes (machines) we dedicate to deploy one or more type of pods. This is a good production practice because we can dedicate machines specifying what they are used for, and in that way we prevent nodes to be shared between different deployments.

Our scripts were designed to be deployed on Google Cloud, so we use GCP expressions to deploy those nods in specific node pools. For example:

```yaml
affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: 'cloud.google.com/gke-nodepool'
                    operator: In
                    values:
                      - services
```

On this example (from https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/4-elasticsearch-deployment.yaml), we deploy the ElasticSearch pods in the ***services*** node pool. So, we created a node pool named services, it has one or more nodes (instances) there, and they are used to deploy these pods.

Same for the cron PHP-FPM (https://github.com/Imagination-Media/magento-k8s/blob/master/scripts/19-magento-cron-phpfpm.yam), we have this:
```ssh
affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: 'cloud.google.com/gke-nodepool'
                    operator: In
                    values:
                      - cron
```
We have a cron node pool we nodes(instances) dedicated to this cron deployment.

### ARM Images
ARM is a new architecture for processors being used by a various number of manufacturers.

Most of the cloud providers have ARM instances that can be used to deploy the infrastructure. They are faster and cheaper than regular x86 and x64 instances.

Google Cloud has [TAU instances](https://www.arm.com/products/silicon-ip-cpu "TAU instances"), AWS has [Graviton instances](https://aws.amazon.com/pt/ec2/graviton/ "Graviton instances"), Azure has [Ampre instances](https://azure.microsoft.com/en-us/blog/azure-virtual-machines-with-ampere-altra-arm-based-processors-generally-available/ "Ampre instances").

This infrastructure is compatible with ARM instances, and we strongly recommend to use them. Make sure the PHP version, ElasticSearch version, and Redis version are compatible and support ARM instances. Some old versions of these services can not be compatible with the ARM architecture.

## GitHub configuration
The following topics are going to describe how to use these scripts along with your Magento codebase repository, and how to set up your GitHub repository with environments, secrets, CI/CD, etc.

### Environments
First of all, we need to create the environments in GitHub for each cloud environment we are going to have. So, for example, if we have the production website, a pre-production environment and a staging environment we will have to create these same three environments in GitHub.

To create the environments please follow [this GitHub guide.](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment "this GitHub guide.")

Please also assign specific branches for each environment. For example, set the master branch on the production branch, staging branch on the staging environment, etc.

### Secrets
[GitHub secrets ](https://docs.github.com/en/actions/security-guides/encrypted-secrets "GitHub secrets") are variables used in our CI/CD process, and they store values as secrets, meaning they are not going to be visible for anyone. We need to set up global secrets and environment secrets. Global secrets are available for all environments, and environment secrets are going to be set on each one of the environments we have created, and they are shared between different environments.

#### General secrets
- **GOOGLE_APPLICATION_CREDENTIALS** - This is used for Google Cloud projects. On this secret we store a base64 encoded service account key. This service account must have access to connect with the Kubernetes cluster where the application was deployed.
- **NODE_AUTH_TOKEN** - [A token generated](https://github.com/settings/tokens "A token generated") from a GitHub account. This token is used to publish the container images, so it must have access to read/publish containers.
- **PROJECT_ID** - This is the Google Cloud project id. Only used for Google Cloud projects.
- **SLACK_WEBHOOK** - The slack webhook URL to notify slack users when the deployment was completed.

#### Environment secrets
- **APP_ETC_ENV** - the Magento app/etc/env.php file used by Magento. An example of this file is:
```php
<?php
return [
    'backend' => [
        'frontName' => 'imadmin'
    ],
    'remote_storage' => [
        'driver' => 'file'
    ],
    'queue' => [
        'consumers_wait_for_messages' => 1,
        'amqp' => [
            'host' => 'rabbitmq-service.magento-demo-production',
            'port' => '5672',
            'user' => 'guest',
            'password' => 'guest',
            'virtualhost' => '/',
            'ssl' => 'false'
        ],
        'topics' => [
            'product_action_attribute.update' => [
                'publisher' => 'amqp-magento'
            ]
        ],
        'config' => [
            'publishers' => [
                'product_action_attribute.update' => [
                    'connections' => [
                        'amqp' => [
                            'name' => 'amqp',
                            'exchange' => 'magento',
                            'disabled' => false
                        ],
                        'db' => [
                            'name' => 'db',
                            'exchange' => 'magento',
                            'disabled' => true
                        ]
                    ]
                ]
            ]
        ],
        'consumers' => [
            'product_action_attribute.update' => [
                'connection' => 'amqp'
            ]
        ]
    ],
    'cron_consumers_runner' => [
        'cron_run' => true,
        'max_messages' => 0,
        'consumers' => [
            'product_action_attribute.update',
            'async.operations.all',
            'codegeneratorProcessor',
            'product_action_attribute.website.update',
            'eshopworld_catalog_product.export',
            'media.storage.catalog.image.resize',
            'matchCustomerSegmentProcessor',
            'exportProcessor',
            'urlRewriteImport',
            'media.content.synchronization',
            'media.gallery.renditions.update',
            'media.gallery.synchronization'
        ]
    ],
    'crypt' => [
        'key' => 'a9733de5cf3df023e3e7ff6d5fac7aef'
    ],
    'db' => [
        'table_prefix' => '',
        'connection' => [
            'default' => [
                'host' => '34.28.146.205',
                'dbname' => 'magento',
                'username' => 'magento',
                'password' => 'yCHU3j972GDj',
                'model' => 'mysql4',
                'engine' => 'innodb',
                'initStatements' => 'SET NAMES utf8;',
                'active' => '1',
                'driver_options' => [
                    1014 => false
                ]
            ],
            'indexer' => [
                'host' => '34.28.146.205',
                'dbname' => 'magento',
                'username' => 'magento',
                'password' => 'yCHU3j972GDj',
                'active' => '1',
                'persistent' => null
            ]
        ]
    ],
    'resource' => [
        'default_setup' => [
            'connection' => 'default'
        ]
    ],
    'x-frame-options' => 'SAMEORIGIN',
    'MAGE_MODE' => 'production',
    'session' => [
        'save' => 'redis',
        'redis' => [
            'host' => 'redis-session-service.magento-demo-production',
            'port' => '6380',
            'password' => '',
            'timeout' => '2.5',
            'persistent_identifier' => '',
            'database' => '0',
            'compression_threshold' => '2048',
            'compression_library' => 'gzip',
            'log_level' => '3',
            'max_concurrency' => '6',
            'break_after_frontend' => '5',
            'break_after_adminhtml' => '30',
            'first_lifetime' => '600',
            'bot_first_lifetime' => '60',
            'bot_lifetime' => '7200',
            'disable_locking' => '1',
            'min_lifetime' => '60',
            'max_lifetime' => '2592000',
            'sentinel_master' => '',
            'sentinel_servers' => '',
            'sentinel_connect_retries' => '5',
            'sentinel_verify_master' => '0'
        ]
    ],
    'cache' => [
        'frontend' => [
            'default' => [
                'id_prefix' => '919_',
                'backend' => 'Magento\\Framework\\Cache\\Backend\\Redis',
                'backend_options' => [
                    'server' => 'redis-fpc-service.magento-demo-production',
                    'database' => '0',
                    'port' => '6379',
                    'password' => '',
                    'compress_data' => '1',
                    'compression_lib' => ''
                ]
            ],
            'page_cache' => [
                'id_prefix' => '919_',
                'backend' => 'Magento\\Framework\\Cache\\Backend\\Redis',
                'backend_options' => [
                    'server' => 'redis-fpc-service.magento-demo-production',
                    'database' => '1',
                    'port' => '6379',
                    'password' => '',
                    'compress_data' => '0',
                    'compression_lib' => ''
                ]
            ]
        ],
        'allow_parallel_generation' => false
    ],
    'lock' => [
        'provider' => 'db',
        'config' => [
            'prefix' => ''
        ]
    ],
    'directories' => [
        'document_root_is_pub' => true
    ],
    'cache_types' => [
        'config' => 1,
        'layout' => 1,
        'block_html' => 1,
        'collections' => 1,
        'reflection' => 1,
        'db_ddl' => 1,
        'eav' => 1,
        'customer_notification' => 1,
        'config_integration' => 1,
        'config_integration_api' => 1,
        'full_page' => 1,
        'translate' => 1,
        'config_webservice' => 1,
        'compiled_config' => 1,
        'target_rule' => 1,
        'config_urapidflow' => 1,
        'vertex' => 1,
        'teamwork_order_history' => 1,
        'globale' => 1,
        'im_menu_catalog' => 1,
        'im_menu_regular' => 1,
        'ec_cache' => 1
    ],
    'downloadable_domains' => [
        'magentodemo.test'
    ],
    'install' => [
        'date' => 'Wed, 12 May 2021 18:08:10 +0000'
    ],
    'system' => [
        'default' => [
            'smile_elasticsuite_core_base_settings' => [
                'es_client' => [
                    'servers' => 'elasticsearch-service.magento-demo-production:9200',
                    'enable_https_mode' => 0,
                    'enable_http_auth' => 1
                ]
            ],
            'admin' => [
                'url' => [
                    'use_custom' => '1'
                ]
            ]
        ]
    ],
    'http_cache_hosts' => [
        [
            'host' => 'varnish'
        ]
    ],
    'db_logger' => [
        'output' => 'disabled'
    ],
    'deployment' => [
        'blue_green' => [
            'enabled' => true
        ]
    ]
];
```
The admin path for the admin must be **IMADMIN**, it's the default admin path for our images.

- **SSH_AUTHORIZED_KEYS** - it's a file with all the public ssh keys that are authorized to SSH into the admin php-fpm pod. For example:
```ssh
#Igor
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChHpe8MuhsBZNdc9SEUPhAwOgtSAb8U9iU9i3tMzOM0qujliwcZ9J4M2sDky+63FkUOnEPEEwb5w2QEvppqHal7lsh1ZN9RNUVbV4pIg+ePjI5534JNlkqHqtHmCmtZW30IYsCEKl+jmub4sd1SG3PpE3P3fcGWxzHH4xfl6+RRrQXw1H/eoksh7KXWTR+zMY5bNJ1h/kk1cY+MobrzeXjnOKPzdp69cTkiMtzqmEDEZutTVpZD6LX02YNbZ7shNVk8ZNfpVZohZQ22DHfbGPkt2KFeQmLQrBJviSlzxxWThq0LGb/oGp93g9fRh4TGKaNd2quhOYfISHwRVWeNOKV igor@imaginationmedia.com
```

- **IMAGE_TAG** - the tag of the image that's going to be released. You can use the environment name (or code) here. For example production for the production website. staging for the staging website, etc.

### Actions
For every environment that we are going to deploy, we must set one GitHub action script, using the example file https://github.com/Imagination-Media/magento-k8s/action-example.yaml.

On the **php-version: '8.1'** value please set the PHP version your project is using.

On **platforms: linux/arm64** set the architecture of the servers you are going to use to host the application. Use platforms: linux/arm64 for arm machines, or platforms: linux/amd64 for x64 machines.

Adjust the name of the images to match your repository name. For example: name: **imagination-media/magento-demo-open-source/nginx**

### Setting up images and scripts
To use this infrastructure with your Magento codebase first create a **server** directory in your codebase with two subdirectories, one named **docker** and another name **k8s**.

Inside the **docker** directory please copy the nginx and phpfpm directories from https://github.com/Imagination-Media/magento-k8s/project-images.

Inside **k8s** create one folder for each environment that you have. For example, production. And then, inside each one of these environment directories you copy the files from https://github.com/Imagination-Media/magento-k8s/scripts.

## Magento Tools
A couple of Magento tools are installed and available to be used on these environments (under the PHP-FPM container). They help developers if the containers are used for development purposes, and even to maintain the website.

### n98-magerun2
[n98-magerun2](https://github.com/netz98/n98-magerun2) CLI Tools provides some handy tools to work with Magento / Mage-OS / Adobe Commerce from command line.

### mage2tv-cache-clean
[mage2tv-cache-clean](https://github.com/mage2tv/magento-cache-clean) is a *bin/magento cache:clean* file watcher. It allows us to clean the cache for specific areas/pages once files that are used in those areas are modified.

### magepack
[magepack](https://github.com/magesuite/magepack) is a bold attempt in making Magento 2 frontend as fast as never before. It builds on experiences gained with Advanced JavaScript bundling guide and Baler to provide the best of both worlds - ease of use and superior performance.

### corediff
[Magento Core Diff](https://github.com/sansecio/corediff) is a tool released by [Sansec](https://sansec.io/getting-started) that allow us to verify if the core code was modified, in that way we can not only see if someone edited the core but also if these changes were made by a malware.