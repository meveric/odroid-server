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
		"3") change_gateway ;;
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
	CURRENT_SUBNET=`grep "subnet" $FILE | cut -d "{" -f1 | sed "s/.$//"`
	SUBNET=$(whiptail --backtitle "$TITLE" --title "Configure Subnet (Subnet IP / Netmask)" --inputbox "Change the values as they seem fitting for you." 0 40 "$CURRENT_SUBNET" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		sed -i "s/$CURRENT_SUBNET/$SUBNET/" $FILE
		restart_server
		ask_for_task
	fi
}

change_range()
{
	CURRENT_RANGE=`cat $FILE | grep range | sed 's/[^0-9\.\ ]*//g' | sed 's/^ //'`
	DHCP_RANGE=$(whiptail --backtitle "$TITLE" --title "Subnet IP-Range" --inputbox "IP-Range" 0 40 "$CURRENT_RANGE" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		sed -i "s/range.*/range $DHCP_RANGE;/" $FILE
		restart_server
		ask_for_task
	fi
}

change_gateway()
{
	CURRENT_GATEWAY=`cat $FILE | grep routers | sed 's/option routers//' | sed 's/;//' | sed 's/\t//' | sed 's/^ //'`
	GATEWAY=$(whiptail --backtitle "$TITLE" --title "Gateway Server" --inputbox "Gateway Server (Router-IP). Multiple Gateways can be separated by comma \",\"" 0 20 "$CURRENT_GATEWAY" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		if [ "x$CURRENT_GATEWAY" != "x" ]; then
			sed -i "s/option routers.*/option routers $GATEWAY;/" $FILE
		else
			sed -i "/# RANGE END/a# ROUTER START\n	option routers $GATEWAY;\n# ROUTER END" $FILE
		fi
		restart_server
		ask_for_task
	fi
}

change_dns()
{
	CURRENT_DNS=`cat $FILE | grep domain-name-servers | sed 's/option domain-name-servers//' | sed 's/;//' | sed 's/\t//' | sed 's/^ //'`
	DNS=$(whiptail --backtitle "$TITLE" --inputbox "DNS Server (separate multiple DNS by comma \",\")" 0 20 "$CURRENT_DNS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		if [ "x$CURRENT_DNS" != "x" ]; then
			sed -i "s/option domain-name-servers.*/option domain-name-servers $DNS;/" $FILE
		else
			sed -i "/# RANGE END/a# DNS START\n  option domain-name-servers $DNS;\n# DNS END" $FILE
		fi
		restart_server
		ask_for_task
	fi
}

change_search()
{
	CURRENT_SEARCH=`cat $FILE | grep "domain-name " | sed 's/option domain-name //' | sed 's/;//' | sed 's/\t//' | sed 's/"//g'`
	DOMAIN=$(whiptail --backtitle "$TITLE" --inputbox "Search Domain" 0 20 "$CURRENT_SEARCH" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		if [ "x$CURRENT_SEARCH" != "x" ]; then
			sed -i "s/option domain-name .*/option domain-name \"$DOMAIN\";/" $FILE
		else
			sed -i "/# RANGE END/a# DOMAIN START\n  option domain-name \"$DOMAIN\";\n# DOMAIN END" $FILE
		fi
		restart_server
		ask_for_task
	fi
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
		restart_server
		ask_for_task
	fi
}

restart_server()
{
	CC=$(whiptail --backtitle "$TITLE" --yesno "DHCP Server configuration changed, do you want to restart server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		service isc-dhcp-server restart
	fi
}

intro
