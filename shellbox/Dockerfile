FROM debian:jessie

ENV container=docker \
    HOME=/root \
    LC_ALL=C \
    DEBIAN_FRONTEND=noninteractive \
    DEBUG=true

RUN apt-get update && \
    apt-get install -y --force-yes wget ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "ForwardToConsole=yes" >> /etc/systemd/journald.conf
RUN cd /lib/systemd/system/sysinit.target.wants/; \
    ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1 \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;

RUN systemctl set-default multi-user.target
RUN systemctl enable ssh

VOLUME [ "/sys/fs/cgroup" ]

ENV init /lib/systemd/systemd

EXPOSE 22

ENTRYPOINT ["/lib/systemd/systemd"]

ADD setup.sh /
RUN bash /setup.sh

