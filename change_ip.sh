#!/bin/bash

# activate DHCP
set_dhcp()
{
	cat <<\EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
EOF
	# restarting network
	echo -e "\033[1;36mRestarting network\033[0;0m"
	sleep 3
	ifdown eth0 && ifup eth0
	sleep 3
	return 0

# TODO: check for additional ethernet and wlan?
}

set_static()
{
	# make sure we have resolvconf installed
	if [ `dpkg --list | grep resolvconf | grep -v rc | wc -l` -lt 1 ]; then
		apt-get install -y resolvconf
	fi
	cat <<\EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
EOF
	# get current IP of possible
	CURRENT_IP=`ifconfig | grep -n1 eth0 | grep "inet addr:" | cut -d ":" -f2 | cut -d " " -f1`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "IP-Address" 0 20 "$CURRENT_IP" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	echo "	address $CC" >> /etc/network/interfaces
	CURRENT_NETMASK=`ifconfig | grep -n1 eth0 | grep "Mask:" | cut -d ":" -f4`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "Netmask" 0 20 "$CURRENT_NETMASK" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	echo "	netmask $CC" >> /etc/network/interfaces
	CURRENT_GATEWAY=`route -n  | grep ^0.0.0.0 | awk '{print $2}'`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "Gateway Server (Router-IP)" 0 20 "$CURRENT_GATEWAY" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	echo "	gateway $CC" >> /etc/network/interfaces
	CURRENT_DNS=`cat /etc/resolv.conf  | grep ^nameserver | head -n 1 | awk '{print $2}'`
	CC=$(whiptail --backtitle "$TITLE" --inputbox "DNS Server (separate multiple DNS by space)" 0 20 "$CURRENT_DNS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	echo "	dns-nameservers $CC" >> /etc/network/interfaces
	CURRENT_SEARCH=`cat /etc/resolv.conf  | grep ^search | head -n 1 | awk '{print $2}'`
        CC=$(whiptail --backtitle "$TITLE" --inputbox "Search Domain" 0 20 "$CURRENT_SEARCH" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
        echo "	dns-search $CC" >> /etc/network/interfaces
	# restarting network
	echo -e "\033[1;36mRestarting network\033[0;0m"
	sleep 3
	ifdown eth0 && ifup eth0
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
				set_dhcp ;;
			2)
				set_static ;;
			*) ;;
		esac
	fi
}
if [ ! -z $1 ]; then
	if [ $1 -eq 1 ]; then
		set_dhcp
	elif [ $1 -eq 2 ]; then
		set_static
	fi
else
	ask_kind
fi
