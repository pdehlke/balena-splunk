#!/bin/bash

# The CloudFront distribution for download.splunk.com seems to have an
# unreliable origin configuration. The arm universalforwarder image file often
# returns 404 repeatedly in succession, and then magically appears & returns 200.
# We retry with an exponential backoff, up to a maximum of 20 times, before we
# return an error to the docker build process.

function retry {
	local retries=$1
	shift

	local count=0
	until "$@"; do
		exit=$?
		wait=$((2 ** $count))
		count=$(($count + 1))
		if [ $count -lt $retries ]; then
			echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
			sleep $wait
		else
			echo "Retry $count/$retries exited $exit, no more retries left."
			return $exit
		fi
	done
	return 0
}

retry 20 wget -qO /tmp/${SPLUNK_FILENAME}.md5 https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/${SPLUNK_PRODUCT}/linux/${SPLUNK_FILENAME}.md5
retry 20 wget -qO /tmp/${SPLUNK_FILENAME} https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/${SPLUNK_PRODUCT}/linux/${SPLUNK_FILENAME}
