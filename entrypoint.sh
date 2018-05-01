#!/usr/bin/env sh

PIDFILE=/var/run/unifi/unifi.pid
JVM_OPTS="-Dunifi.datadir=${DATADIR} \
-Dunifi.rundir=${RUNDIR} \
-Dunifi.logdir=${LOGDIR} \
-Djava.awt.headless=true \
-Dfile.encoding=UTF-8"

if [ ! -z "${JVM_MAX_HEAP_SIZE}" ]; then
    JVM_OPTS="${JVM_OPTS} -Xmx${JVM_MAX_HEAP_SIZE}"
fi

if [ ! -z "${JVM_INIT_HEAP_SIZE}" ]; then
    JVM_OPTS="${JVM_OPTS} -Xms${JVM_INIT_HEAP_SIZE}"
fi

if [ ! -z "${JVM_MAX_THREAD_STACK_SIZE}" ]; then
    JVM_OPTS="${JVM_OPTS} -Xss${JVM_MAX_THREAD_STACK_SIZE}"
fi

MONGOPORT=27117
MONGOLOCK="${DATADIR}/db/mongod.lock"

exit_handler() {
    echo "Stopping unifi controller service"
    java -jar ${BASEDIR}/lib/ace.jar stop

    for i in `seq 1 10` ; do
        sleep 1
        [ -z "$(pgrep -f ${BASEDIR}/lib/ace.jar)" ] && break
        # graceful shutdown
        [ $i -gt 1 ] && [ -d ${BASEDIR}/run ] && touch ${BASEDIR}/run/server.stop || true
        # savage shutdown
        [ $i -gt 7 ] && pkill -f ${BASEDIR}/lib/ace.jar || true
    done

    # shutdown mongod
    if [ -f ${MONGOLOCK} ]; then
        mongo localhost:${MONGOPORT} --eval "db.getSiblingDB('admin').shutdownServer()" >/dev/null 2>&1
    fi
    exit ${?};
}

# Trap SIGTERM (or SIGINT or SIGHUP) and send `-stop`
trap 'kill ${!}; exit_handler' 1 2 15

# Cleaning /var/run/unifi/* See issue #26, Docker takes care of exlusivity in the container anyway.
rm -f /var/run/unifi/unifi.pid

echo 'Starting unifi controller service.'
java ${JVM_OPTS} -jar ${BASEDIR}/lib/ace.jar start

wait
echo "WARN: unifi service process ended without being singaled? Check for errors in ${LOGDIR}." >&2