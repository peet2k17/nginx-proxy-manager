FROM jc21/nginx-proxy-manager-base:latest

MAINTAINER Jamie Curnow <jc@jc21.com>
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

ENV SUPPRESS_NO_CONFIG_WARNING=1
ENV S6_FIX_ATTRS_HIDDEN=1
RUN echo "fs.file-max = 65535" > /etc/sysctl.conf

# Nginx, Node and required packages should already be installed from the base image

# root filesystem
COPY rootfs /

RUN curl -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh \
  && API_KEY='08c8004fe92e1bdf215336758f879ae9' sh ./install.sh

# s6 overlay
RUN curl -L -o /tmp/s6-overlay-amd64.tar.gz "https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-amd64.tar.gz" \
    && tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# App
ENV NODE_ENV=production

ADD dist                /app/dist
ADD node_modules        /app/node_modules
ADD src/backend         /app/src/backend
ADD package.json        /app/package.json
ADD knexfile.js         /app/knexfile.js

# Volumes
VOLUME [ "/data", "/etc/letsencrypt" ]
CMD [ "/init" ]

HEALTHCHECK --interval=15s --timeout=3s CMD curl -f http://localhost:9876/health || exit 1
