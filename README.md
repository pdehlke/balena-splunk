# Splunk universal forwarder for balena raspberryPi 4

This project illustrates a method for using a splunk universal forwarder to send logs from an app container in a [Balena](https://balena.io) application on a Raspberry Pi 4 to a remote splunk indexer.

## Major design concerns
* Getting the arm forwarder to run on an rPi 4 isn't too difficult. See [splunk/Dockerfile.template](splunk/Dockerfile.template), where we run 
`dpkg --add-architecture armhf && apt-get update && apt-get install -y libc6:armhf libstdc++6:armhf wget && ln -s /lib/arm-linux-gnueabihf/ld-2.30.so /lib/ld-linux.so.3`
* download.splunk.com is not hugely reliable when retrieving the ARM universal forwarder. See [splunk/usr/local/bin/get-splunk.sh](splunk/usr/local/bin/get-splunk.sh)
* Permissions on shared data volumes can be a little tricky. 
	* Each container defines a `COMMON_UID` and `COMMON_GID` that we can use to manage file ownership across containers.
	* Pay attention to the `apache` [Dockerfile.template](apache/Dockerfile.template). We have to set an appropriate `umask` for apache log files, set group ownership of the logs directory to `COMMON_GID`, and then, since `apt` starts apache2 at install time, remove the initial log files it creates. You'll have to adapt and adjust this process for whatever application you're running- just make sure that in the app container(s), log files and directories are readable by `COMMON_UID` or `COMMMON_GID`
* The splunk forwarder configuration is set in the [splunk/opt](splunk/opt) directory, and copied in to the splunk container wholesale.
	* Adjust the values in [opt/splunk/etc/system/local/outputs.conf](splunk/opt/splunk/etc/system/local/outputs.conf) to your splunk installation.
	* In production, I use Splunk Cloud for index/search. You'd set this up the same way you would on any other forwarder: copy the contents of your splunk cloud UF config package to `splunk/opt/splunk/etc/apps` and things should Just Work(TM).
*  Have a look at [splunk/usr/local/bin/entrypoint.sh](splunk/usr/local/bin/entrypoint.sh). Balena (and docker) containers' hostname is typically meaningless; what we really care about is the name of the Balena device that logs are coming from. We use a quick `sed` expression to change the hostname in [etc/system/local/inputs.conf](splunk/opt/splunk/etc/system/local/inputs.conf) to the value of `${BALENA_DEVICE_NAME_AT_INIT}`, which is much more meaningful to humans. Adjust to your preference.
*  Be aware that your applications should rotate their log files, to avoid filling the shared log volume. SD cards have improved a lot, but also be aware that extensive writing and erasing will eventually cause an SD card to fail from fatigue.

## Future work
This was a quick Friday afternoon hackathon project. The splunk container is fairly large at this point (~325 MB); slimming it down is likely to be quite a project- the splunk app itself is large- accounting for the bulk of the container size- and due to libc dependencies, porting to Alpine appears at first glance to be fraught with peril. PRs- for image size or any other consideration- are 100% welcome!