FROM       debian:stable
MAINTAINER Seth0r "https://github.com/seth0r"

RUN apt-get update
RUN apt-get dist-upgrade -y

RUN apt-get install -y vim procps net-tools \
    gzip cpio wget gettext git \
    qemu-kvm socat openssh-client \
    iptables iproute2

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN touch /root/.inside_docker

COPY dist /dist

COPY *.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*.sh

VOLUME /data

CMD ["/usr/local/sbin/run.sh"]
