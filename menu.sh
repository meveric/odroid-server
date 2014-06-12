#!/bin/bash

while true
do
	CC=$(whiptail --backtitle "ODROID Server Menu" --menu "Main Menu" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		"1" "Set/Change local IP address - (NOT INCLUDED YET)" \
		"2" "Change Hostname - (NOT INCLUDED YET)" \
                "3" "Install and configure DHCP-Server - (NOT INCLUDED YET)" \
                "4" "Install and configure DNS-Server (Bind) - (NOT INCLUDED YET)" \
                "5" "Install amd configure OwnCloud Server - (NOT INCLUDED YET)" \
                3>&1 1>&2 2>&3)

	RET=$?

	if [ $RET -eq 1 ]; then
		exit 1
	elif [ $RET -eq 0 ]; then
		case "$CC" in
		"1") . $HOMEDIR/change_ip.sh ;;
		"2") . $HOMEDIR/change_hostname.sh ;;
		"3") . $HOMEDIR/dhcp_server.sh ;;
		"4") . $HOMEDIR/dns_server.sh ;;
		"5") . $HOMEDIR/owncloud_server.sh ;;
		*) msgbox "Error 001. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	fi
done

