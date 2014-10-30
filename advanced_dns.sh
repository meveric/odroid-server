#!/bin/bash
intro()
{
	msgbox "Here you can reconfigure your DNS server or add more advanced options such as additional ZONES."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to continue?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		ask_for_task
	fi
}

ask_for_task()
{
	CC=$(whiptail --backtitle "$TITLE" --menu "What do you want to change?" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		"1"	"Reconfigure DNS-forwarder" \
		"2"	"Reconfigure DNS-zones" \
		"3"	"Add/Remove DNS-Entries" \
	3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		case "$CC" in
		"1") change_forwarder ;;
		"2") change_zones ;;
		"3") change_entries ;;
		*) msgbox "Error 006. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	else
		return 0
	fi
}

change_forwarder()
{
	if [ -f /etc/bind/conf.d/named.conf.options ] && [ `cat /etc/bind/conf.d/named.conf.options | grep forwarders | wc -l` -ge 1 ]; then
		OLD_FORWARDER=`cat /etc/bind/conf.d/named.conf.options | grep -A1 forwarders | grep -v forwarders | sed "s/\t//g" | sed "s/;//"`
	fi
	FORWARDER=$(whiptail --backtitle "$TITLE" --title "DNS-Forwareder" --inputbox "IP-Address for DNS forwarding (leave empty for no forwarder)" 0 20 "$OLD_FORWARDER" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ "x$FORWARDER" != "x" ]; then
		# TODO maybe only replace forwarder instead of entirely rewrite the file? -> in case user did manual changes
		echo "options {
	forwarders {
		$FORWARDER;
	};
};" > /etc/bind/conf.d/named.conf.options
	else
		# delete content of file see TODO above
		echo > /etc/bind/conf.d/named.conf.options
	fi
	restart_server
}

change_zones()
{
	CC=$(whiptail --backtitle "$TITLE" --menu "What do you want to change?" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		"1"     "Remove DNS-Zone" \
		"2"	"Add DNS-Zone" \
	3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		case "$CC" in
		"1") remove_zone ;;
		"2") add_zone ;;
		*) msgbox "Error 007. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	else
		return 0
	fi
}

remove_zone()
{
	select_zone
	CC=$(whiptail --backtitle "$TITLE" --yesno "Are you sure you want to remove the DNS-Zone $ZONE?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		rm -f $FILE
		ZONE_START=`grep -n "zone \"$ZONE\"" /etc/bind/conf.d/named.conf.zones | cut -d ":" -f1`
		ZONE_END=$((`grep -n "zone \"" /etc/bind/conf.d/named.conf.zones | cut -d ":" -f1 | grep -A1 $ZONE_START | grep -v $ZONE_START`-1))
		if [ "x$ZONE_END" != "x" ]; then
			sed -i "$ZONE_START,${ZONE_END}d" /etc/bind/conf.d/named.conf.zones
		else
			# dirty but should work for end of file
			ZONE_END=$(($ZONE_START+99))
			sed -i "$ZONE_START,${ZONE_END}d" /etc/bind/conf.d/named.conf.zones
		fi
		restart_server
	fi
}

add_zone()
{
	echo "WIP"
}

select_zone()
{
	OPTIONS=""
	FILE=""
	OIFS="$IFS"
	NUM_FILES=`find /etc/bind/conf.d -type f | grep "db\." | wc -l`
	i=0
	IFS="$(printf '\n\t')"
	for files in `find /etc/bind/conf.d -type f | grep "db\."`
	do
		ZONES=`echo $files | cut -d "." -f3-`
		OPTIONS="$ZONES	$(($NUM_FILES-$i))
$OPTIONS"
		i=$(($i+1))
	done
	ZONE=$(whiptail --backtitle "$TITLE" --menu "Select Subnet to reconfigure" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		$OPTIONS \
		3>&1 1>&2 2>&3)
	IFS="$OIFS"
	if [ $? -eq 0 ]; then
		FILE=/etc/bind/conf.d/db.$ZONE
	fi
}		

change_entries()
{
	select_zone
	echo "WIP"
}

restart_server()
{
	CC=$(whiptail --backtitle "$TITLE" --yesno "DNS Server configuration changed, do you want to restart server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		service bind9 restart
	fi
}

intro
