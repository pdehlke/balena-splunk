#!/bin/bash

set -e

sed -i "/^host /s/=.*$/= ${BALENA_DEVICE_NAME_AT_INIT}/" /opt/splunk/etc/system/local/inputs.conf

if [[ ! -f /opt/splunk/etc/splunk-launch.conf ]]; then
	cp /opt/splunk/etc/splunk-launch.conf.default /opt/splunk/etc/splunk-launch.conf
	chown splunk /opt/splunk/etc/splunk-launch.conf
fi

${SPLUNK_HOME}/bin/splunk start --accept-license --no-prompt

trap "${SPLUNK_HOME}/bin/splunk stop" SIGINT SIGTERM EXIT

tail -n 0 -f ${SPLUNK_HOME}/var/log/splunk/splunkd_stderr.log &

wait
