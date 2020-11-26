FROM debian:buster-slim

ARG MAILPILE_VERSION=master

ENV TZ "Etc/GMT"
ENV MAILPILE_GNUPG/GA "/usr/bin/gpg-agent"
ENV MAILPILE_GNUPG/DM "/usr/bin/dirmngr"
ENV MAILPILE_TOR "/usr/bin/tor"
ENV MAILPILE_OPENSSL "/usr/bin/openssl"
ENV MAILPILE_GNUPG "/usr/bin/gpg"
ENV MAILPILE_VERSION ${MAILPILE_VERSION}

# Install requirements
RUN apt-get update && apt-get install -y \
    # base system packages
    ca-certificates git gnupg1 openssl python-pip spambayes tor tzdata zlib1g \
    # required Python modules
    python-appdirs python-cffi python-dns python-fasteners \
    python-icalendar python-jinja2 python-lxml python-markupsafe python-pbr \
    python-pgpdump python-pil python-socks python-stem \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/gpg1 /usr/bin/gpg

RUN ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "$TZ" > /etc/timezone && date

ADD entrypoint.sh /entrypoint.sh

EXPOSE 33411
VOLUME /root/.local/share/Mailpile
VOLUME /root/.gnupg

CMD /entrypoint.sh
