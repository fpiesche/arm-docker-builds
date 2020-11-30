# Build the game in a base container
FROM alpine:latest AS builder
LABEL "Maintainer" "Florian Piesche <florian@yellowkeycard.net>"
ENV SERVERBIN ioq3ded
ENV BUILD_CLIENT 0
RUN \
  apk --no-cache add curl g++ gcc git make && \
  git clone https://github.com/ioquake/ioq3 /tmp/ioq3 && \
  cd /tmp/ioq3 && \
  make && \
  make copyfiles

# Copy the game files from the builder container to a new image to minimise size
FROM alpine:latest AS ioq3srv
LABEL "Maintainer" "Florian Piesche <florian@yellowkeycard.net>"
RUN adduser ioq3srv -D
COPY --from=builder /usr/local/games/quake3 /usr/local/games/quake3
COPY files/ /usr/local/games/quake3/

USER ioq3srv
EXPOSE 27960/udp
VOLUME [ "/usr/local/games/quake3/baseq3"]
ENTRYPOINT ["/usr/local/games/quake3/entrypoint.sh"]
