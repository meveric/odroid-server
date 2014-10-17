#!/bin/bash

intro()
{
        msgbox "Here you can reconfigure your DHCP server or add more advanced options such as static IP-Addresses for specific devices."
        CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to continue?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
		check_configs
                ask_for_subnet
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

ask_for_subnet()
{
	OPTIONS=""
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
		"6"	"Configure devices with static IPs" \
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
	CC=$(whiptail --backtitle "$TITLE" --menu "What do you want to change?" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		"1"     "Add new device with static IP address" \
		"2"     "Remove device with static IP address" \
		"3"     "Modify a device with static IP address" \
	3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		case "$CC" in
		"1") add_static ;;
		"2") remove_static ;;
		"3") modify_static ;;
		*) msgbox "Error 003. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	else
		ask_for_task
	fi
}

add_static()
{
	MAC=$(whiptail --backtitle "$TITLE" --inputbox "MAC-Address for system with static IP (format aa:bb:cc:dd:ee:ff):" 0 20 "" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ] && [ "x$MAC" != "x" ]; then
		IP=$(whiptail --backtitle "$TITLE" --inputbox "Static IP for new device:" 0 20 "" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ] && [ "x$IP" != "x" ]; then
			NAME=$(whiptail --backtitle "$TITLE" --inputbox "Hostname of the device (will be used as an identifier):" 0 40 "" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
			if [ $? -eq 0 ] && [ "x$NAME" != "x" ]; then
				sed -i "/# RANGE END/a# HOST $NAME START\nhost $NAME {\n	hardware ethernet $MAC;\n	fixed-address $IP;\n}\n# HOST $NAME END" $FILE
			else
				ask_for_task
			fi
		else
			ask_for_task
		fi
	else
		ask_for_task
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to add another device?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		add_static
	else
		restart_server
		ask_for_task
	fi
}

get_static()
{
	OPTIONS=""
	NUM_DEVICES=`grep "^host" $FILE | wc -l`
	i=0
	if [ $NUM_DEVICES -ge 1 ]; then
		for DEVICE in `grep "^host" $FILE | sed "s/^host //" | sed "s/ {//"`
		do
			# TODO find menu with only value without label
			OPTIONS="$DEVICE	$(($NUM_DEVICES-$i))
$OPTIONS"
			i=$(($i+1))
		done
	else
		msgbox "No devices with static IPs found in this subnet"
		ask_for_task
        fi	
}

remove_static()
{
	get_static
	CC=$(whiptail --backtitle "$TITLE" --menu "Select Device to remove:" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		$OPTIONS \
	3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
		START=`grep -n "^# HOST $CC START" $FILE | cut -d ":" -f1`
		END=`grep -n "^# HOST $CC END" $FILE | cut -d ":" -f1`
		sed -i "${START},${END}d" $FILE
		
               	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to remove another device?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			remove_static
		else
			restart_server
			ask_for_task
		fi
        else
              	ask_for_task
        fi
}

modify_static()
{
	# TODO put restart somewhere
	get_static
	DEVICE=$(whiptail --backtitle "$TITLE" --menu "Select Device to modify:" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		$OPTIONS \
	3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		CC=$(whiptail --backtitle "$TITLE" --menu "What do you want to modify?" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
			"1"	"Change name/identifyer" \
			"2"	"Change MAC address" \
			"3"	"Change IP address" \
		3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			case "$CC" in
			"1") change_name_static ;;
			"2") change_mac_static ;;
			"3") change_ip_static ;;
			*) msgbox "Error 004. Please report on the forums" && exit 0 ;;
			esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
			CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to modify another device?" 0 0 3>&1 1>&2 2>&3)
			if [ $? -eq 0 ]; then
				modify_static
			fi
		else
			ask_for_task
		fi
	else
		ask_for_task
	fi
}

change_name_static()
{
	NAME=$(whiptail --backtitle "$TITLE" --inputbox "New hostname of the device (will be used as an identifier):" 0 40 "$DEVICE" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ] && [ "x$NAME" != "x" ]; then
		sed -i "s/^# HOST $DEVICE START/# HOST $NAME START/" $FILE
		sed -i "s/^# HOST $DEVICE END/# HOST $NAME END/" $FILE
		sed -i "s/^host $DEVICE {/host $NAME {/" $FILE
	else
		msgbox "Nothing will be changed."
	fi
}

change_mac_static()
{
	OLD_MAC=`grep -a3 "^# HOST $DEVICE START" $FILE | grep "hardware ethernet" | sed "s/hardware ethernet//" | sed "s/\t//g" | sed "s/ //g" | sed "s/;//"`
	MAC=$(whiptail --backtitle "$TITLE" --inputbox "New MAC-Address for system with static IP (format aa:bb:cc:dd:ee:ff):" 0 20 "$OLD_MAC" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ] && [ "x$MAC" != "x" ]; then
		sed -i "s/hardware ethernet $OLD_MAC/hardware ethernet $MAC/" $FILE
	else
		msgbox "Nothing will be changed."
	fi
}

change_ip_static()
{
	OLD_IP=`grep -a3 "^# HOST $DEVICE START" $FILE | grep "fixed-address" | sed "s/fixed-address//" | sed "s/\t//g" | sed "s/ //g" | sed "s/;//"`
	IP=$(whiptail --backtitle "$TITLE" --inputbox "New static IP for new device:" 0 20 "$OLD_IP" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ] && [ "x$IP" != "x" ]; then
		sed -i "s/fixed-address $OLD_IP/fixed-address $IP/" $FILE
	else
		msgbox "Nothing will be changed."
	fi
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
