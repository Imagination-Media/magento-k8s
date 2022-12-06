FROM ghcr.io/imagination-media/magento-k8s/php-fpm:8.1

# Install Golang
RUN curl -O https://dl.google.com/go/go1.19.3.linux-arm64.tar.gz && \
    tar xvf go1.19.3.linux-arm64.tar.gz && \
    chown -R root:root ./go && \
    mv go /usr/local && \
    export GOPATH=$HOME/work && \
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Google Cloud SDK
RUN apt-get install apt-transport-https ca-certificates gnupg -y && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install google-cloud-cli -y

# Install gcsfuse
RUN apt-get install kmod -y
RUN apt-get install fuse -y
RUN /usr/local/go/bin/go install github.com/googlecloudplatform/gcsfuse@latest
