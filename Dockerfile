FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

ENV PKGURL=https://dl.ui.com/unifi/5.13.32/unifi_sysvinit_all.deb

RUN apt-get update && \
  apt-get install -qy --no-install-recommends \
  ca-certificates \
  apt-transport-https \
  gnupg2 \
  curl && \
  echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" > /etc/apt/sources.list.d/mongodb-org.list && \
  echo "deb https://www.ui.com/downloads/unifi/debian stable ubiquiti" > /etc/apt/sources.list.d/unifi.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50 && \
  apt-get update && \
  curl -L -o ./unifi.deb "${PKGURL}" && \
  apt-get -qy install openjdk-8-jre-headless mongodb-org && \
  apt -qy install ./unifi.deb && \
  rm -f ./unifi.deb && \
  rm -rf /var/lib/apt/lists/*

RUN java -version

ENV BASEDIR=/usr/lib/unifi \
  DATADIR=/var/lib/unifi \
  RUNDIR=/var/run/unifi \
  LOGDIR=/var/log/unifi \
  JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
  JVM_MAX_HEAP_SIZE=1024M \
  JVM_INIT_HEAP_SIZE=

RUN ln -s ${LOGDIR} ${BASEDIR}/logs && \
  ln -s ${RUNDIR} ${BASEDIR}/run && \
  ln -s ${DATADIR} ${BASEDIR}/data

VOLUME ["${DATADIR}", "${RUNDIR}", "${LOGDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp 27117

WORKDIR ${BASEDIR}

COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
COPY prune.sh /prune.sh
COPY prune.js /prune.js
RUN chmod +x /entrypoint.sh && chmod +x /prune.sh && chmod +x /healthcheck.sh

HEALTHCHECK --start-period=5m CMD /healthcheck.sh || exit 1

ENTRYPOINT ["/entrypoint.sh"]

CMD ["unifi"]
