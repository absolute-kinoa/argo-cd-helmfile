# Custom Dockerfile to install required helm plugins
FROM quay.io/argoproj/argocd:v3.3.2

USER root
# Download OS dependencies
RUN apt-get update && \
    apt-get install -y \
        curl git wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# https://github.com/helm/helm/releases
ARG HELM3_VERSION="v3.20.0"
ARG HELM4_VERSION="v4.1.1"
# https://github.com/helmfile/helmfile/releases
ARG HELMFILE_VERSION="1.2.3"
ARG HELM_VALS_VERSION="0.43.3"
ARG HELM_SECRETS_VERSION="v4.7.5"

RUN wget -qO- "https://get.helm.sh/helm-${HELM4_VERSION}-linux-amd64.tar.gz" | tar zxv --strip-components=1 -C /tmp linux-amd64/helm && mv /tmp/helm /usr/local/bin/helm-v4 &&\
    wget -qO- "https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz" | tar zxv --strip-components=1 -C /tmp linux-amd64/helm && mv /tmp/helm /usr/local/bin/helm &&\
    wget -qO- "https://github.com/helmfile/vals/releases/download/v${HELM_VALS_VERSION}/vals_${HELM_VALS_VERSION}_linux_amd64.tar.gz" | tar zxv -C /usr/local/bin vals

RUN chmod 755 /usr/local/bin/helm* /usr/local/bin/vals

USER argocd

# Install helm-secrets plugin (as argocd user)
RUN helm plugin install https://github.com/jkroepke/helm-secrets --version "$HELM_SECRETS_VERSION"

ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"
