FROM alpine:latest

# Set up base image
RUN apk add --no-cache openssh openssh-sftp-server && \
    # Create /var/run/sshd
    mkdir -p /var/run/sshd && \
    # Remove default host keys
    rm -f /etc/ssh/ssh_host_*key*

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/entrypoint /

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
