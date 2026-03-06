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
    wget -qO- "https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz" | tar zxv --strip-components=1 -C /tmp linux-amd64/helm && mv /tmp/helm /usr/local/bin/helm-v3 &&\
    wget -qO- "https://github.com/helmfile/vals/releases/download/v${HELM_VALS_VERSION}/vals_${HELM_VALS_VERSION}_linux_amd64.tar.gz" | tar zxv -C /usr/local/bin vals

COPY src/*.sh /usr/local/bin/

RUN ln -sf /usr/local/bin/helm-v3 /usr/local/bin/helm && \
    chown root:root /usr/local/bin/* && chmod 755 /usr/local/bin/*

USER argocd

WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./
WORKDIR /home/argocd

# Plugin Versions
##

# https://github.com/databus23/helm-diff/releases
ARG HELM_DIFF_VERSION="3.15.0"
# https://github.com/aslafy-z/helm-git/releases
ARG HELM_GIT_VERSION="1.5.2"
# https://github.com/jkroepke/helm-secrets/releases
ARG HELM_SECRETS_VERSION="4.7.5"

## Install Plugins
##
RUN \
  helm plugin install https://github.com/databus23/helm-diff   --version ${HELM_DIFF_VERSION} && \
  helm plugin install https://github.com/aslafy-z/helm-git     --version ${HELM_GIT_VERSION} && \
  helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION}

ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"
