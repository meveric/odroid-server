#!/bin/bash
# helper functions
msgbox() {
        # $1 is the msg
        whiptail --backtitle "$TITLE" --msgbox "$1" 0 0 0
}
get_updates() {
	# only check for updates once a day not every single time
	if [ -f /var/cache/apt/pkgcache.bin ]; then
		LAST_UPDATE=`stat -c %Y /var/cache/apt/pkgcache.bin`
		DATE=`date +%s`
		UPDATE_AGE=$(($DATE-$LAST_UPDATE))
		if [ $UPDATE_AGE -gt $((60*60*24)) ]; then
			apt-get update
		fi
	else
		apt-get update
	fi
}

