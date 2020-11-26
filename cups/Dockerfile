# FROM balenalib/raspberry-pi-debian:buster
FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

# labels
LABEL maintainer="Florian Piesche <florian@yellowkeycard.net>" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="florianpiesche/cups-arm" \
  org.label-schema.description="Simple CUPS docker image for armv6 (Raspberry Pi Zero)" \
  org.label-schema.version="0.1" \
  org.label-schema.url="https://hub.docker.com/r/florianpiesche/cups-arm"

RUN apt-get update && apt-get install -y \
  curl \
  cups \
  cups-client \
  cups-bsd \
  printer-driver-all \
  printer-driver-gutenprint \
  hpijs-ppds \
  hp-ppd  \
  hplip \
  printer-driver-foo2zjs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ADD cupsd.conf /etc/cups/cupsd.conf
ADD docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 631

ENTRYPOINT ["/docker-entrypoint.sh"]
