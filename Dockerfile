# FROM debian:stretch-slim
FROM ubuntu:xenial

ARG DEBIAN_FRONTEND=noninteractive

ENV PKGURL=https://dl.ubnt.com/unifi/5.6.36/unifi_sysvinit_all.deb

RUN apt-get update && \
  mkdir -p /usr/share/man/man1/ && \
  mkdir -p /var/cache/apt/archives/ && \
  apt-get install -qy --no-install-recommends \
    ca-certificates-java \
    openjdk-8-jre-headless \
    curl && \
  sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d && \
  echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.6 main" > /etc/apt/sources.list.d/mongodb-org.list && \
  echo "deb http://www.ubnt.com/downloads/unifi/debian stable unifi" > /etc/apt/sources.list.d/unifi.list && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50 && \
  apt-get update && \
  curl -L -o ./unifi.deb "${PKGURL}" && \
  apt -qy install mongodb-org-server ./unifi.deb && \
  rm -f ./unifi.deb && \
  apt-get clean -qy && \
  apt-get purge -qy --auto-remove \
    dirmngr \
    gnupg && \
  rm -rf /var/lib/apt/lists/*

ENV BASEDIR=/usr/lib/unifi \
  DATADIR=/var/lib/unifi \
  RUNDIR=/var/run/unifi \
  LOGDIR=/var/log/unifi \
  JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
  JVM_MAX_HEAP_SIZE=1024M \
  JVM_INIT_HEAP_SIZE=

VOLUME ["${DATADIR}", "${RUNDIR}", "${LOGDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp

WORKDIR ${BASEDIR}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK CMD curl -kILs --fail https://localhost:8443 || exit 1

CMD ["/entrypoint.sh"]
