#!/bin/sh
# Every 10 seconds, check for files modified since we last checked
# if there is activity, it means motion was recently detected
# Since file writes begin immediately on motion detected, and don't end until approx 1min after motion ends, we only need to look for files modified very recently
# Relies on running mp4record process
prev_notification="NoData"
last_uploaded="NoData"

chmod -R 0775 /home/hd1/record/
cd /home/hd1/record/

if [ -n "$1" ]; then
  DROPBOX_TOKEN="$1"
else
  echo "Error: Missing Dropbox App Token, exiting ..."
  exit 1
fi

if [ -n "$2" ]; then
  TLS_PROXY_URL="$2"
else
  echo "Error: Missing ssl proxy url eg. 'http://192.168.1.10', exiting ..."
  exit 1
fi

if [ -n "$3" ]; then
  HA_API_URL="$3"
else
  echo "Error: Missing HomeAssistant api url eg. 'http://192.168.1.10:8123', exiting ..."
  exit 1
fi

if [ -n "$4" ]; then
	# eg. sensor.frontdoor_motion
  HA_SENSOR="$4"
else
  echo "Error: Missing HomeAssistant sensor eg. 'sensor.frontdoor_motion', exiting ..."
  exit 1
fi

if [ -n "$5" ]; then
  HA_AUTH_TOKEN="-H x-ha-access: ${5}"
else
  HA_AUTH_TOKEN=""
fi

touch last_motion_check
sleep 2 # since we /just/ created last_motion_check, the first check can return a false negative unless we wait a beat - was 5

# Check we havn't got too many files on disk, impairing performance.
timeout -t 5 find . -type f -name "*.mp4*" -newer last_motion_check
if [ $? -gt 0 ]
then
	# experienced a timeout.  The disk is probably too slow.
	echo "WARNING !! Disk is performing poorly, detection may not perform in a timely fashion."
	notification="{\"state\": \"Error\"}"
	/home/curl --fail --silent --show-error -X POST ${HA_AUTH_TOKEN} -H "Content-Type: application/json" -d "$notification" ${HA_API_URL}/api/states/sensor.frontdoor_motion
fi

# Enter our motion loop
while true; do
	echo "Checking for motion at `date`..."
	has_motion=$([ -z "`find . -type f -name "*.mp4*" -newer last_motion_check`" ] && echo "false" || echo "true")
	echo `date +%s` > last_motion_check
	armed=$(ps | grep mp4record | grep -v grep -q && echo "true" || echo "false")
	if [ $armed == "false" ]
	then
		# Flag as error if camera not armed.
		notification="{\"state\": \"Error\"}"
	else
		notification="{\"state\": \"$has_motion\"}"
	fi

	if [ "$prev_notification" != "$notification" ]
	then
		# New state condition, we should update homeassistant ...
	  # echo "$notification"
		echo "Sending state change to HomeAssistant"
		echo "State changed from: \"$prev_notification\" to \"$notification\""
		echo "Timestamp pre-post `date`..."
	  /home/curl --fail --silent --show-error -X POST ${HA_AUTH_TOKEN} -H "Content-Type: application/json" -d "$notification" ${HA_API_URL}/api/states/sensor.frontdoor_motion
		echo "Timestamp post `date`..."
		if [ $? != 0 ]
		then
			echo "Failed to notify HomeAssistant of state: ${notification}"
		else
			# Set our notification state.
			prev_notification=$notification
		fi
		# Curl output is usually missing carraige return
		echo ""
	fi

	# echo "Timestamp pre-motion_file `date`..."
	motion_file=$(find . -type f -name "*.mp4" -mmin -1 | tail -1)
	# echo "Timestamp post-motion_file `date`..."
	# echo "Motion file: \"$motion_file\""
	chmod -R 0775 /home/hd1/test/http/
	echo $motion_file | sed "s/.\//record\//" > /home/hd1/test/http/motion
	if [ -n "$motion_file" ]
	then
		# Check we aren't about to upload a dupe.
		if [ "$motion_file" != "$last_uploaded" ]
		then
			DATE_STAMP=$(date +%Y%m%d-%H%M%S)
			FILE_NAME="${DATE_STAMP}.mp4"
			echo "Uploading footage to dropbox @ $DATE_STAMP"
			/home/curl --fail --silent --show-error -H "Authorization: Bearer ${DROPBOX_TOKEN}" "${TLS_PROXY_URL}/1/files_put/auto/${FILE_NAME}" -T "$motion_file" &
			# echo "Timestamp post-upload fork `date`..."
			if [ $? != 0 ]
			then
				echo "Non-zero from curl process."
			else
				last_uploaded=$motion_file
			fi
		fi
	fi
	sleep 10
done
