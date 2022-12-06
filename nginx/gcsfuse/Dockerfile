FROM ghcr.io/imagination-media/magento-k8s/nginx:latest

# Execute the startup bash script on the startup
COPY startup.sh /docker-entrypoint.d/00-nginx-conf-mod.sh
RUN chmod 755 /docker-entrypoint.d/00-nginx-conf-mod.sh
RUN chmod +x /docker-entrypoint.d/00-nginx-conf-mod.sh

# Install Python 3
RUN apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev
RUN curl -O https://www.python.org/ftp/python/3.9.1/Python-3.9.1.tgz
RUN tar -xf Python-3.9.1.tgz
RUN cd Python-3.9.1
RUN ./configure --enable-optimizations
RUN make -j 2
RUN make altinstall
RUN cd ../ && rm -rf Python-3.9.1 && rm -rf Python-3.9.1.tgz

# Install Golang
RUN curl -O https://dl.google.com/go/go1.19.3.linux-arm64.tar.gz && \
    tar xvf go1.19.3.linux-arm64.tar.gz && \
    chown -R root:root ./go && \
    mv go /usr/local && \
    export GOPATH=$HOME/work && \
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Google Cloud SDK
RUN mkdir -p /root/.config/gcloud && echo "$GKE_SERVICE_ACCOUNT_KEY" >> /root/.config/gcloud/application_default_credentials.json
RUN apt-get install apt-transport-https ca-certificates gnupg -y
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get install -y apt-transport-https
RUN apt-get update
RUN apt-get install google-cloud-cli -y

# Install gcsfuse
RUN apt-get install kmod -y
RUN apt-get install fuse -y
RUN /usr/local/go/bin/go install github.com/googlecloudplatform/gcsfuse@latest

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
