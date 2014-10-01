#!/bin/bash

intro()
{
        msgbox "Here you can setup your ethernet controllers to either use DHCP or a static IP address to configure your network."
        CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to configure your ethernet adapters now?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
                check_network_adapters
        fi
}

check_network_adapters()
{
	adapter=`. ./get_network_adapters.sh`
	ask_kind
}

# activate DHCP
set_dhcp()
{
	if [ `grep "auto $1" /etc/network/interfaces | wc -l` -lt 1 ]; then
		echo "auto $1" >> /etc/network/interfaces
	fi
	start=`grep -n "iface $1" /etc/network/interfaces | cut -d ":" -f1`
	if [ ! -z $start ]; then
		# only check for 10 lines after declaration of iface $1 to see if there are other ifaces present
		for i in 1 2 3 4 5 6 7 8 9 10
		do
			if [ `grep -A$i "iface $1" /etc/network/interfaces | grep iface | wc -l` -eq 2 ]; then
				end=$(($start+$i-1))
				break;
			fi
		done
		if [ ! -z $end ]; then
			del="${start},${end}d"
			sed -i ${del// /} /etc/network/interfaces
			sed -i "/auto $1/a\iface $1 inet dhcp\n" /etc/network/interfaces
		fi
	else
		echo "iface $1 inet dhcp" >> /etc/network/interfaces	
	fi
	# restarting network
	echo -e "\033[1;36mRestarting network\033[0;0m"
	sleep 3
	ifdown $1 && ifup $1
	sleep 3
	return 0		
}

set_static()
{
	# make sure we have resolvconf installed
	if [ `dpkg --list | grep resolvconf | grep -v rc | wc -l` -lt 1 ]; then
		apt-get install -y resolvconf
	fi
	if [ `grep "auto $1" /etc/network/interfaces | wc -l` -lt 1 ]; then
		echo "auto $1" >> /etc/network/interfaces
	fi
	# get current IP of possible
	CURRENT_IP=`ifconfig | grep -n1 $1 | grep "inet addr:" | cut -d ":" -f2 | cut -d " " -f1`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "IP-Address" 0 20 "$CURRENT_IP" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ -z $CC ]; then
		msgbox "IP-Address can not be left blank!
A valid IP-Address looks something like 192.168.0.1"
		. $HOMEDIR/change_ip.sh static $1
		return 0
	fi
	config="	address $CC"
	CURRENT_NETMASK=`ifconfig | grep -n1 $1 | grep "Mask:" | cut -d ":" -f4`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "Netmask" 0 20 "$CURRENT_NETMASK" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ -z $CC ]; then
		msgbox "Netmask can not be left blank!
A valid Netmask looks something like 255.255.255.0"
		. $HOMEDIR/change_ip.sh static $1
		return 0
	fi
	config="$config\n	netmask $CC"
	CURRENT_GATEWAY=`route -n  | grep ^0.0.0.0 | awk '{print $2}'`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "Gateway Server (Router-IP)" 0 20 "$CURRENT_GATEWAY" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ ! -z $CC ]; then
		config="$config\n	gateway $CC"
	fi
	CURRENT_DNS=`cat /etc/resolv.conf  | grep ^nameserver | head -n 1 | awk '{print $2}'`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "DNS Server (separate multiple DNS by space)" 0 20 "$CURRENT_DNS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	# TODO use 127.0.0.1 as DNS instead?
	if [ ! -z $CC ]; then
		config="$config\n	dns-nameservers $CC"
	fi
	CURRENT_SEARCH=`cat /etc/resolv.conf  | grep ^search | head -n 1 | awk '{print $2}'`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "Search Domain" 0 20 "$CURRENT_SEARCH" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ ! -z $CC ]; then
		config="$config\n	dns-search $CC"
	fi
	start=`grep -n "iface $1" /etc/network/interfaces | cut -d ":" -f1`
	if [ ! -z $start ]; then
		# only check for 10 lines after declaration of iface $1 to see if there are other ifaces present
		for i in 1 2 3 4 5 6 7 8 9 10
		do
			if [ `grep -A$i "iface $1" /etc/network/interfaces | grep iface | wc -l` -eq 2 ]; then
				end=$(($start+$i-1))
				break
			fi
		done
		if [ ! -z $end ]; then
			del="${start},${end}d"
			sed -i ${del// /} /etc/network/interfaces
			sed -i "/auto $1/a\ iface $1 inet static\n$config" /etc/network/interfaces
		fi
	else
		echo "iface $1 inet static\n$config" >> /etc/network/interfaces
	fi
        # restarting network
        echo -e "\033[1;36mRestarting network\033[0;0m"
        sleep 3
	ifdown $1 && ifup $1
        sleep 3
        return 0
}

ask_kind()
{
	CC=$(whiptail --backtitle "$TITLE" --menu "IP Config" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
                "1" "Get IP over DHCP" \
                "2" "Set static IP" \
                3>&1 1>&2 2>&3)
	result=$?
	if [ $result -eq 1 ]; then
		return 0
	elif [ $result -eq 0 ]; then
		case "$CC" in
                        1)
				set_dhcp $adapter;;
			2)
				set_static $adapter;;
			*) ;;
		esac
	fi
}
if [ ! -z $1 ] && [ ! -z $2 ]; then
	if [ $1 = "dhcp" ]; then
		set_dhcp $2
	elif [ $1 = "static" ]; then
		set_static $2
	fi
else
	intro
fi
