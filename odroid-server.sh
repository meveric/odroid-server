#!/bin/bash

# ODROID Server Setup

# For debug uncomment
 set -x

# Global defines
HOMEDIR="/root/odroid-server"

check_root() 
{
	if [ $UID -ne 0 ]; then
		echo -e "\033[1;31mYou must run this script with root priviledges.\033[0;0m"
		echo -e "try \033[1;36msudo $0\033[0;0m"
		exit 0
	fi
        
	prerequirements
	# only move on if requirements are met
	if [ $? -eq 0 ]; then
		update_scripts
	fi

}
prerequirements() 
{
	echo -e "\033[1;36mWe wanna make sure necessary packages are installed\033[0;0m"
	sleep 5
	#only check for updates once a day not every single time
	LAST_UPDATE=`stat -c %Y /var/lib/apt/periodic/update-success-stamp`
	DATE=`date +%s`
	UPDATE_AGE=$(($DATE-$LAST_UPDATE))
	if [ $UPDATE_AGE -gt $((60*60*24)) ]; then
		apt-get update
	fi
	# in case someone removed these
        apt-get -y install git whiptail
}

update_scripts() 
{
	echo -e "\033[1;36mMake sure we have the latest version of the scripts\033[0;0m"
	sleep 3
	cd $HOMEDIR
	git pull
	
}
# load extra functions
. $HOMEDIR/functions.sh
# check permissions
check_root
# load menu
. menu.sh
