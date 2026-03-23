# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
# Modifications © 2026 Epitech

FROM docker.io/debian:trixie-slim

LABEL org.opencontainers.image.base.name="docker.io/debian/trixie:26.04" \
      org.opencontainers.image.description="Application packaged by Epitech" \
      org.opencontainers.image.documentation="https://github.com/epitech-ops/containers/argocd-helmfile/README.md" \
      org.opencontainers.image.source="https://github.com/epitech-ops/containers/argocd-helmfile" \
      org.opencontainers.image.title="argocd-helmfile" \
      org.opencontainers.image.vendor="Epitech"

ENV DEBIAN_FRONTEND=noninteractive \
ARGOCD_USER_ID=999

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

## Install required packages and dependencies
##
RUN apt-get update && apt-get install --no-install-recommends -y \
  ca-certificates \
  git git-lfs \
  unzip \
  wget \
  jq && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Create argocd user and group, and set permissions for the home directory
##
RUN groupadd -g $ARGOCD_USER_ID argocd && \
  useradd -l -r -u $ARGOCD_USER_ID -g argocd argocd && \
  mkdir -p /  home/argocd && \
  chown argocd:0 /home/argocd && \
  chmod g=u /home/argocd

# Binary Versions
# https://github.com/helm/helm/releases
ARG HELM3_VERSION="v3.20.0"
ARG HELM4_VERSION="v4.1.1"
# https://github.com/helmfile/helmfile/releases
ARG HELMFILE_VERSION="1.2.3"
# https://github.com/mikefarah/yq/releases
ARG YQ_VERSION="v4.45.4"
ARG HELM_VALS_VERSION="0.43.3"
ARG OP_VERSION="v2.32.1"

RUN \
  GO_ARCH="amd64" && \
  wget -q --show-progress --progress=bar:force:noscroll -O- "https://get.helm.sh/helm-${HELM4_VERSION}-linux-${GO_ARCH}.tar.gz" | tar zxv --strip-components=1 -C /tmp linux-${GO_ARCH}/helm && mv /tmp/helm /usr/local/bin/helm-v4 && \
  wget -q --show-progress --progress=bar:force:noscroll -O- "https://get.helm.sh/helm-${HELM3_VERSION}-linux-${GO_ARCH}.tar.gz" | tar zxv --strip-components=1 -C /tmp linux-${GO_ARCH}/helm && mv /tmp/helm /usr/local/bin/helm-v3 && \
  wget -q --show-progress --progress=bar:force:noscroll -O- "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /usr/local/bin helmfile && \
  wget -q --show-progress --progress=bar:force:noscroll -O "/usr/local/bin/yq"       "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${GO_ARCH}" && \
  wget -q --show-progress --progress=bar:force:noscroll -O-                          "https://github.com/helmfile/vals/releases/download/v${HELM_VALS_VERSION}/vals_${HELM_VALS_VERSION}_linux_${GO_ARCH}.tar.gz" | tar zxv -C /usr/local/bin vals && \
  wget -q --show-progress --progress=bar:force:noscroll "https://cache.agilebits.com/dist/1P/op2/pkg/${OP_VERSION}/op_linux_${GO_ARCH}_${OP_VERSION}.zip" -O op.zip && \
  unzip -d op op.zip &&  mv op/op /usr/local/bin/ && rm -r op.zip op && \
  true

COPY src/*.sh /usr/local/bin/

RUN \
  ln -sf /usr/local/bin/helm-v3 /usr/local/bin/helm && \
  chown root:root /usr/local/bin/* && chmod 755 /usr/local/bin/*

ENV USER=argocd
USER $ARGOCD_USER_ID

WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./
WORKDIR /home/argocd

ENV HELM_CACHE_HOME=/home/argocd/helm/cache
ENV HELM_CONFIG_HOME=/home/argocd/helm/config
ENV HELM_DATA_HOME=/home/argocd/helm/data

# plugin versions
# https://github.com/databus23/helm-diff/releases
ARG HELM_DIFF_VERSION="3.15.2"
# https://github.com/aslafy-z/helm-git/releases
ARG HELM_GIT_VERSION="1.5.2"
# https://github.com/jkroepke/helm-secrets/releases
ARG HELM_SECRETS_VERSION="4.7.5"

RUN \
  helm-v3 plugin install https://github.com/databus23/helm-diff   --version ${HELM_DIFF_VERSION} && \
  helm-v3 plugin install https://github.com/aslafy-z/helm-git     --version ${HELM_GIT_VERSION} && \
  helm-v3 plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} && \
  true

# array is exec form, string is shell form
# this binary in injected via a shared folder with the repo server
#ENTRYPOINT [/var/run/argocd/argocd-cmp-server]
