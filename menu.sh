#!/bin/bash
while true
do
	if [ ! -z $REBOOT ]; then
        	RESTART="--- restart required ---"
	fi
	TITLE="ODROID Server Setup $RESTART"
	CC=$(whiptail --backtitle "$TITLE" --menu "Main Menu" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		" 1" "Set/Change local IP address (ethernet adapters only)" \
		" 2" "Change Hostname" \
		" 3" "resize partition to full size" \
                " 4" "Install and configure DHCP-Server (one ethernet adapter only)" \
		" 4.1" "        Advanced DHCP Configuration" \
                " 5" "Install and configure DNS-Server (Bind) - (basic functions only)" \
		" 5.1" "        Advanced DNS Configuration" \
                " 6" "Install and configure OwnCloud Server - (NOT INCLUDED YET)" \
		" 7" "Install and configure Samba 4 Active Directory Domain - (NOT INCLUDED YET)" \
		" 8" "Install and configure Samba Server (Windows File Sharing) - (NOT INCLUDED YET)" \
		" 9" "Install and configure OpenVPN (VPN Server) - (NOT INCLUDED YET)" \
		"10" "Install and configure PPPOE (DSL Internet connection - on eth0)" \
                3>&1 1>&2 2>&3)

	RET=$?

	if [ $RET -eq 1 ]; then
		if [ ! -z $REBOOT ]; then
			CC=$(whiptail --backtitle "$TITLE" --yesno "System needs to reboot for changes to take effect.
Do you want to reboot now?" 0 0 3>&1 1>&2 2>&3)
			if [ $? -eq 0 ]; then
				reboot
			fi
		fi
		exit 1
	elif [ $RET -eq 0 ]; then
		case "$CC" in
		" 1") . $HOMEDIR/change_ip.sh ;;
		" 2") . $HOMEDIR/change_hostname.sh ;;
		" 3") . $HOMEDIR/fs_resize.sh ;;
		" 4") . $HOMEDIR/dhcp_server.sh ;;
		" 4.1") . $HOMEDIR/advanced_dhcp.sh ;;
		" 5") . $HOMEDIR/dns_server.sh ;;
		" 5.1") . $HOMEDIR/advanced_dns.sh ;;
		" 6") . $HOMEDIR/owncloud_server.sh ;;
		" 7") . $HOMEDIR/ad_server.sh ;;
		" 8") . $HOMEDIR/samba_server.sh ;;
		" 9") . $HOMEDIR/openvpn_server.sh ;;
		"10") . $HOMEDIR/pppoe.sh ;;
		*) msgbox "Error 001. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	fi
done
