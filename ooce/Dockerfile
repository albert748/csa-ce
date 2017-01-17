# -*- conf -*-

FROM hpsoftware/useitwithcsacodar:ooce1062
MAINTAINER Albert Zhou <shengboz@hpe.com>

EXPOSE 8443
VOLUME [ "/share", "/etc/postgresql", "/var/lib/postgresql", "/var/log/postgresql" ]


ENV dockerclient_hostname=p.absz.me \
    dockerclient_ipaddress=10.0.0.10 \
    dockerclient_port=18443

COPY [ "ContentPacks/*.jar", "dockercentral.sh", "/tmp/"]

ENTRYPOINT [ "/bin/bash", "-c", "/tmp/dockercentral.sh" ]