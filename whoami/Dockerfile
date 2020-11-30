FROM golang:alpine3.6 AS builder
RUN apk add git && git clone https://github.com/jwilder/whoami/ /app
WORKDIR /app
RUN go build -o http

FROM alpine:3.6
WORKDIR /app
ENV PORT 8000
EXPOSE 8000
COPY --from=builder /app/http /app
CMD ["/app/http"]
