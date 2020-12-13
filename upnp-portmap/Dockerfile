FROM alpine:latest

RUN apk --no-cache add bash grep curl miniupnpc
ADD portmap.sh /

ENTRYPOINT /portmap.sh