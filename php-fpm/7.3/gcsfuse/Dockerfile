FROM ghcr.io/imagination-media/magento-k8s/php-fpm:7.3

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
RUN apt-get install apt-transport-https ca-certificates gnupg -y
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update
RUN apt-get install kmod -y
RUN apt-get install google-cloud-cli -y

# Install gcsfuse
RUN apt-get install fuse -y
RUN /usr/local/go/bin/go install github.com/googlecloudplatform/gcsfuse@latest

# Expose SSH port
EXPOSE 22

# Execute the startup bash script on the startup
COPY startup.sh /root/startup.sh
ENTRYPOINT ["/bin/bash", "/root/startup.sh"]
