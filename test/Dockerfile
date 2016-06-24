FROM debian:jessie

RUN apt-get update && \
    apt-get install -y --force-yes \
        wget \
        ssh \
        telnet \
        apt-transport-https \
        ca-certificates \
        git &&\
    apt-key adv \
        --keyserver hkp://pgp.mit.edu:80 \
        --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
    echo "deb https://apt.dockerproject.org/repo debian-jessie main" >> \
        /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --force-yes docker-engine && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN git clone https://github.com/sstephenson/bats.git && \
    bash bats/install.sh /usr

WORKDIR /test
