ftp_upload/ftp_upload.sh
==============

This script copies recorded video files to a ftp server (on a NAS for example).

Configure the script in **yi-hack.cfg** :

* FTP_HOST: the IP of the NAS.
* FTP_PORT: port of the FTP server.
* FTP_USER: username to use when connecting to ftp server.
* FTP_PASS: password of the ftp user account.
* FTP_DIR: path where you want the videos copied.

Outputs errors to ftp_upload/log.txt

Add the script to the crontab of your Yi Home Camera to run automatically.

Script source:

* https://github.com/fritz-smh/yi-hack/pull/125

housekeeper/housekeeper.sh
====================

This script searches for and deletes old video files.

Outputs errors to housekeeper/log.txt

Configure the script in **yi-hack.cfg**

* Gateway offline duration
If you schedule your router to go offline (during midnight for example).

* GW_OFF_START: Start time of offline duration. Ex: 23:00
* GW_OFF_END: End time of offline duration. Ex: 02:00

Please use 24h format.
Leave blank if not use.

* Housekeeping options
* RETRY_TO_ALERT: Number of unreachable pings to Gateway before alerting by yellow led flashing
* RECORD_KEEP_DAYS: Number days that recorded videos are kept. Older ones are deleted.

Add the script to the crontab of your Yi Home Camera to run automatically.

Script source:

* https://github.com/fritz-smh/yi-hack/pull/125
