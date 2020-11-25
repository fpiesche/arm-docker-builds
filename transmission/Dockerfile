FROM --platform=$TARGETPLATFORM alpine

RUN apk add --no-cache transmission-daemon transmission-cli shadow
RUN usermod -u 1000 transmission && groupmod -g 1000 transmission

ADD --chown=transmission ./transmission-root/ /

EXPOSE 9091:9091 51413

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "pgrep", "transmission-daemon" ]

USER transmission
ENTRYPOINT [ "transmission-daemon", "-f", "-g", "/config", "-c", "/watch", "-w", "/downloads", "--incomplete-dir", "/downloads/_incomplete", "-er", "--dht", "--no-auth" ]
