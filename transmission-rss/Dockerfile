FROM --platform=$TARGETPLATFORM ruby:alpine
ARG UID=1000
ARG GID=1000

RUN \
  addgroup -g $GID transmission-rss && \
  adduser -u $UID -G transmission-rss -D transmission-rss && \
  apk --no-cache --update add build-base libffi-dev
RUN gem install transmission-rss

COPY --chown=transmission-rss:transmission-rss \
  ./transmission-rss.conf /home/transmission-rss/.config/transmission-rss/config.yml

USER transmission-rss
ENTRYPOINT [ "transmission-rss" ]
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 CMD [ "pgrep", "-F", "/tmp/transmission-rss.pid" ]
