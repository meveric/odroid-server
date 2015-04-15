#!/bin/bash

menu_maintenance()
{
	CC=$(whiptail --backtitle "$TITLE" --menu "Main Menu" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		" 1" "Set/Change local IP address (ethernet adapters only)" \
		" 2" "Change Hostname" \
		" 3" "Resize partition to full size" \
		" 4" "Change username" \
		3>&1 1>&2 2>&3)
	if [ $?	-eq 1 ]; then
		return
	else
		case "$CC" in
		" 1") . $HOMEDIR/change_ip.sh ;;
		" 2") . $HOMEDIR/change_hostname.sh ;;
		" 3") . $HOMEDIR/fs_resize.sh ;;
		" 4") . $HOMEDIR/change_user.sh;;
		*) msgbox "Error 001. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	fi
}

menu_install()
{
	CC=$(whiptail --backtitle "$TITLE" --menu "Main Menu" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		" 1" "Install and configure DHCP-Server (one ethernet adapter only)" \
		" 1.1" "        Advanced DHCP Configuration" \
		" 2" "Install and configure DNS-Server (Bind) - (basic functions only)" \
		" 2.1" "        Advanced DNS Configuration (WIP)" \
		" 3" "Install and configure OwnCloud Server - (Own private cloud server)" \
		" 4" "Install and configure Samba 4 Active Directory Domain" \
		" 5" "Install and configure Samba Server (Windows File Sharing) - (NOT INCLUDED YET)" \
		" 6" "Install and configure OpenVPN (VPN Server)" \
		" 6.1" "        Create Client Certificates for VPN" \
		" 7" "Install and configure PPPOE (DSL Internet connection - on eth0)" \
		" 8" "Install and configure Jabber (XMPP) Server - Openfire" \
		" 9" "Install and configure Mumble (Low latency VoIP server) Server" \
		"10" "Install and configure Linux Dash (WebBased System Monitor)" \
		"11" "Install and configure BackupPC (Linux system backup software)" \
		"11.1" "        Configure clients for BackupPC" \
		3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		return
	else
		case "$CC" in
		" 1") . $HOMEDIR/dhcp_server.sh ;;
		" 1.1") . $HOMEDIR/advanced_dhcp.sh ;;
		" 2") . $HOMEDIR/dns_server.sh ;;
		" 2.1") . $HOMEDIR/advanced_dns.sh ;;
		" 3") . $HOMEDIR/owncloud_server.sh ;;
		" 4") . $HOMEDIR/ad_server.sh ;;
		" 5") . $HOMEDIR/samba_server.sh ;;
		" 6") . $HOMEDIR/openvpn_server.sh ;;
		" 6.1") . $HOMEDIR/openvpn_clients.sh ;;
		" 7") . $HOMEDIR/pppoe.sh ;;
		" 8") . $HOMEDIR/jabber_server.sh;;
		" 9") . $HOMEDIR/mumble_server.sh;;
		"10") . $HOMEDIR/linux_dash.sh;;
		"11") . $HOMEDIR/backuppc.sh;;
		"11.1") . $HOMEDIR/backuppc_clients.sh;;
		*) msgbox "Error 001. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	fi
}

while true
do
	if [ ! -z $REBOOT ]; then
		RESTART="--- restart required ---"
	fi
	TITLE="ODROID Server Setup $RESTART"
	CC=$(whiptail --backtitle "$TITLE" --menu "Main Menu" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		"1" "Server Maintenance" \
		"2" "Install and Configure Servers" \
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
		"1")	menu_maintenance;;
		"2")	menu_install;;
		*) msgbox "Error 001. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC << Report on the forums"
	fi
done
