FROM alpine:latest
LABEL maintainer="Florian Piesche <florian@yellowkeycard.net>"
ARG ARCH=armhf
ARG VERSION=0.7.4

ENV DOWNLOAD_URL https://github.com/jwilder/docker-gen/releases/download/$VERSION/docker-gen-alpine-linux-${ARCH}-${VERSION}.tar.gz
ENV DOCKER_HOST unix:///tmp/docker.sock

RUN apk -U add openssl
RUN wget -qO- $DOWNLOAD_URL | tar xvz -C /usr/local/bin
RUN mkdir -p /etc/docker-gen/templates && wget https://raw.githubusercontent.com/nginx-proxy/nginx-proxy/master/nginx.tmpl -O /etc/docker-gen/templates/nginx.tmpl

ENTRYPOINT ["/usr/local/bin/docker-gen"]
