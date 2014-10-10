#!/bin/bash

intro()
{
        msgbox "Here you can reconfigure your DHCP server or add more advanced options such as static IP-Addresses for specific devices."
        CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to continue?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
		check_configs
                check_network_adapters
        fi
}

check_configs()
{
	NUMCONFIGS=`ls /etc/dhcp/conf.d/ | wc -l`
	if [ ! -d /etc/dhcp/conf.d/] || [ $NUMCONFIGS -lt 1 ]; then
		msgbox "There is no subnet configured yet. Please run DHCP Server config first."
		CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a DHCP server now?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			. $HOMEDIR/dhcp_server.sh
			# TODO probably better to do a rerun of check_configs here instead of quiting?
			return 0
		fi
	fi
}

check_network_adapters()
{
	
        adapter=`. $HOMEDIR/get_network_adapters.sh`
	ask_for_subnet
}

ask_for_subnet()
{
	for files in `find /etc/dhcp/conf.d -type f`
	do
		ID=`echo $files | cut -d "." -f3`
		SUBNET=`grep "subnet" $files | cut -d "{" -f1`
		OPTIONS="\"$ID\" \"$SUBNET\" \\
$OPTIONS"
	done
	CC=$(whiptail --backtitle "$TITLE" --menu "Select Subnet to reconfigure" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		$OPTIONS \
		3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
       		FILE=/etc/dhcp/conf.d/config.$CC 
	else
		return 0	
	fi
	
}

intro
