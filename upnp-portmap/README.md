
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

Simply add the `upnp.forward_ports` label to your service and set it to the ports you want to forward:

    version: "3.7"

    services:
      ioquake3_ffa:
        image: florianpiesche/ioquake3-arm:armv6
        deploy:
          labels:
            - "upnp.forward_ports=27960"
        environment:
          - STARTUP_CONFIG=configs/ffa.cfg
          - SERVER_MOTD="pew pew"
        volumes:
          - baseq3:/usr/share/games/quake3/baseq3
          - qconfigs:/usr/share/games/quake3/configs
        restart: unless-stopped
        ports:
          - 27960:27960
