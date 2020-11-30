FROM arm32v6/golang:alpine AS builder
RUN apk add --no-cache git && git clone https://github.com/jwilder/whoami/ /app
WORKDIR /app
RUN go build -o http

FROM arm32v6/alpine
WORKDIR /app
ENV PORT 8000
EXPOSE 8000
COPY --from=builder /app/http /app
CMD ["/app/http"]
