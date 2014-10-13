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
	if [ ! -d /etc/dhcp/conf.d/ ] || [ $NUMCONFIGS -lt 1 ]; then
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
	OIFS="$IFS"
	IFS="$(printf '\n\t')"
	for files in `find /etc/dhcp/conf.d -type f`
	do
		ID=`echo $files | cut -d "." -f3`
		SUBNET=`grep "subnet" $files | cut -d "{" -f1 | sed "s/.$//"`
		OPTIONS="$ID	$SUBNET
$OPTIONS"
	done
	CC=$(whiptail --backtitle "$TITLE" --menu "Select Subnet to reconfigure" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		$OPTIONS \
		3>&1 1>&2 2>&3)
	IFS="$OIFS"
        if [ $? -eq 0 ]; then
       		FILE=/etc/dhcp/conf.d/config.$CC
		ask_for_task
	else
		return 0	
	fi
}

ask_for_task()
{
	CC=$(whiptail --backtitle "$TITLE" --menu "What do you want to change?" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		"1"	"Reconfigure subnet" \
		"2"	"Reconfigure IP-Range" \
		"3"	"Reconfigure Default Gateway" \
		"4"	"Reconfigure DNS Servers" \
		"5"	"Reconfigure Search-Domain" \
		"6"	"Add or Reconfigure static IPs for specific device" \
		"7"	"Configure autoregistration on DNS Server" \
		"8"	"Remove subnet" \
	3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		case "$CC" in
		"1") change_subnet ;;
		"2") change_range ;;
		"3") change_router ;;
		"4") change_dns ;;
		"5") change_search ;;
		"6") change_static ;;
		"7") change_autodns ;;
		"8") remove_subnet ;;
		*) msgbox "Error 002. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	else
		return 0
	fi
}

change_subnet()
{
	echo "WIP"
}

change_range()
{
	echo "WIP"
}

change_router()
{
	echo "WIP"
}

change_dns()
{
	echo "WIP"
}

change_search()
{
	echo "WIP"
}

change_static()
{
	echo "WIP"
}

change_autodns()
{
	echo "WIP"
}

remove_subnet()
{
	CC=$(whiptail --backtitle "$TITLE" --yesno "Are you sure you want to completely remove the subnet?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		rm -f $FILE
		DELETE=`grep -n "$FILE" "/etc/dhcp/dhcpd.conf" | cut -d ":" -f1`
		sed -i "${DELETE}d" /etc/dhcp/dhcpd.conf
		# TODO check if it was running previously? Ask for restart?
		service isc-dhcp-server restart
	fi
}

intro
