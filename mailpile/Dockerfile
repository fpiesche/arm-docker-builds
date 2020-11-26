FROM debian:buster-slim

ARG GID=1000
ARG UID=1000
ARG DEBIAN_FRONTEND=noninteractive

ENV MAILPILE_GNUPG_AGENT="/usr/bin/gpg-agent" \
    MAILPILE_GNUPG_DIRMNGR="/usr/bin/dirmngr" \
    MAILPILE_TOR="/usr/sbin/tor" \
    MAILPILE_OPENSSL="/usr/bin/openssl" \
    MAILPILE_GNUPG="/usr/bin/gpg1"

RUN apt-get update && \
    # Install basic requirements
    apt-get install -y curl apt-transport-https gnupg1 && \
    curl -s https://packages.mailpile.is/deb/key.asc && \
    # Add mailpile repo
    curl -s https://packages.mailpile.is/deb/key.asc | apt-key add - && \
    echo "deb https://packages.mailpile.is/deb nightly main" | tee /etc/apt/sources.list.d/000-mailpile.list && \
    # Add user for mailpile
    groupadd -g $GID mailpile && useradd -u $UID -g $GID -m mailpile && \
    # Install mailpile
    apt-get update && apt-get install -y mailpile && \
    # Start tor
    update-rc.d tor defaults && service tor start && \
    # Set up mailpile
    su - mailpile -c 'mailpile setup' && \
    # Tidy up apt
    apt-get clean

# Expose port and set up a volume for data persistence
EXPOSE 33411
VOLUME /home/mailpile/.local/share/Mailpile

# Run mailpile
USER mailpile
WORKDIR /home/mailpile
CMD mailpile --www=0.0.0.0:33411 --wait
