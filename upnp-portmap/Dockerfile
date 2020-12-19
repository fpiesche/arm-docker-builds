FROM alpine:latest

RUN apk --no-cache add bash grep curl miniupnpc
ADD portmap.sh /

ENV DOCKER_SOCKET=/var/run/docker.sock UPDATE_FREQ=60

CMD bash -x /portmap.sh