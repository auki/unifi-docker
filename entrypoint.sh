#!/usr/bin/env sh

# JSVC - for running java apps as services
JSVC=$(command -v jsvc)
if [ -z ${JSVC} -o ! -x ${JSVC} ]; then
    log_failure_msg "${DESC}: jsvc is missing!"
    exit 1
fi

PIDFILE=/var/run/unifi/unifi.pid
JVM_OPTS="
-Dunifi.datadir=${DATADIR}
-Dunifi.rundir=${RUNDIR}
-Dunifi.logdir=${LOGDIR}
-Djava.awt.headless=true
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

JSVC_OPTS="
-home ${JAVA_HOME}
-classpath /usr/share/java/commons-daemon.jar:${BASEDIR}/lib/ace.jar
-pidfile ${PIDFILE}
-procname unifi
-outfile ${LOGDIR}/unifi.out.log
-errfile ${LOGDIR}/unifi.err.log
${JVM_OPTS}"

# One issue might be no cron and lograte, causing the log volume to become bloated over time! Consider `-keepstdin` and `-errfile &2` options for JSVC.
MAINCLASS='com.ubnt.ace.Launcher'

MONGOPORT=27117
MONGOLOCK="${DATADIR}/db/mongod.lock"

exit_handler() {
    echo "Stopping unifi controller service"
    ${JSVC} ${JSVC_OPTS} -stop ${MAINCLASS} stop
    # ${JSVC} -nodetach -pidfile ${PIDFILE} -stop ${MAINCLASS} stop

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
trap 'kill ${!}; exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM

# Cleaning /var/run/unifi/* See issue #26, Docker takes care of exlusivity in the container anyway.
rm -f /var/run/unifi/unifi.pid

# Keep attached to shell so we can wait on it
echo 'Starting unifi controller service.'
${JSVC} ${JSVC_OPTS} ${MAINCLASS} start

wait

echo "WARN: unifi service process ended without being singaled? Check for errors in ${LOGDIR}." >&2
exit 1
