FROM golang:1.15-alpine AS go-builder

ARG DOCKER_GEN_VERSION=0.7.4

# Install build dependencies for docker-gen
RUN apk add --update \
        curl \
        gcc \
        git \
        make \
        musl-dev

# Build docker-gen
RUN go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
    && git checkout $DOCKER_GEN_VERSION \
    && make get-deps \
    && make all

RUN git clone https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion/ /docker-letsencrypt-nginx-proxy-companion


FROM alpine:3.11 as image
LABEL maintainer="Yves Blusseau <90z7oey02@sneakemail.com> (@blusseau)"

ENV DEBUG=false \
    DOCKER_HOST=unix:///var/run/docker.sock

# Install packages required by the image
RUN apk add --update \
        bash \
        ca-certificates \
        coreutils \
        curl \
        jq \
        openssl \
        py3-cryptography \
    && rm /var/cache/apk/*

# Install docker-gen from build stage
COPY --from=go-builder /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/
COPY --from=go-builder /docker-letsencrypt-nginx-proxy-companion/install_simp_le.sh /app/
COPY --from=go-builder /docker-letsencrypt-nginx-proxy-companion/app/ /app/

# Install simp_le
RUN chmod +rx /app/install_simp_le.sh \
    && sync \
    && /app/install_simp_le.sh \
    && rm -f /app/install_simp_le.sh

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
