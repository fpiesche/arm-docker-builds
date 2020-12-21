
# How to deploy

    version: "3.7"

    services:
      upnp_portforward:
        image: florianpiesche/upnp-portmap-arm:armv6
        deploy:
          placement:
            constraints:
              - node.role==manager
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
        networks:
          - host

    networks:
    host:
        external: true

# How to use

Simply add the `upnp.forward_ports` label to your service and set it to the service's internal
ports you want to forward. Separate multiple ports with spaces. Note that forwarding ports won't
work if they're not published outside of the container.

    services:
      traefik:
        image: traefik/traefik
        deploy:
          labels:
            - "upnp.forward_ports=80 443"
          placement:
            constraints:
              - node.role==manager
        
        ports:
          - target: 80
            published: 81
          - target: 443
            published: 444
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
