#!/bin/bash
# DNS-Server (Bind) installation and configuration

# check if we run on DHCP or static IP
check_dhcp()
{
	if [ `cat /etc/network/interfaces | grep "iface eth0" | grep dhcp | wc -l` -ge 1 ]; then
		# dhcp is still active but we need a static IP address in order to do activate DHCP server
		CC=$(whiptail --backtitle "$TITLE" --yesno "You don't have a static IP address, but we need this to setup the DNS server.
Do you want to setup a static IP address now?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			. $HOMEDIR/change_ip.sh static
		else
			msgbox "DNS Server can't be configured without a static IP address."
			return 0
		fi
	fi
	install_dns_server
}

install_dns_server()
{
	
        if [ `dpkg --list | grep bind9 | grep -v rc | awk '{print $2}' | grep bind9$ | wc -l` -eq 0  ]; then
		apt-get install -y bind9
		if [ ! $? -eq 0 ]; then
			msgbox "Installation failed, please ask for help in forums"
			return 0
		fi
	fi
	configure_dns_server
}

configure_dns_server()
{
	# TODO check if forwarder is already configured
	if [ `cat /etc/bind/named.conf.options | grep forwarders | grep -v // | wc -l` -ge 1 ]; then
		# do crazy stuff with it
		continue
	fi
	# let's start with some easy options
	CC=$(whiptail --backtitle "$TITLE" --yesno "You can use a router or other DNS Server as a forwarder to redirect unknown IP-Addresses to that server.
Do you want to activate a DNS-forwarder?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		# make sure we have our own space for configs
		if [ ! -d /etc/bind/conf.d/ ]; then
			mkdir /etc/bind/conf.d/
			chmod 755 /etc/bind/conf.d
		fi
		CURRENT_DNS=`cat /etc/resolv.conf  | grep ^nameserver | head -n 1 | awk '{print $2}'`		
		FORWARDER=$(whiptail --backtitle "$TITLE" --title "DNS-Forwareder" --inputbox "IP-Address" 0 20 "$CURRENT_DNS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
		if [ ! -z $FORWARDER ]; then
			echo "options {
	forwarders {
		$FORWARDER;
	};
};" > /etc/bind/conf.d/named.conf.options
			if [ `cat /etc/bind/named.conf | grep /etc/bind/conf.d/named.conf.options | wc -l` -lt 1 ]; then
				echo "include \"/etc/bind/conf.d/named.conf.options\";" >> /etc/bind/named.conf
			fi
		fi
	fi
	# TODO check for existing namezones?
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to create a new namezone?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		CURRENT_SEARCH=`cat /etc/resolv.conf  | grep ^search | head -n 1 | awk '{print $2}'`
		NAMEZONE=$(whiptail --backtitle "$TITLE" --inputbox "New NameZone" 0 20 "$CURRENT_SEARCH" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
		if [ ! -f /etc/bind/conf.d/named.conf.zones ]; then
			echo "zone \"$NAMEZONE\" {
	type master;
	file \"/etc/bind/conf.d/db.$NAMEZONE\";
};" > /etc/bind/conf.d/named.conf.zones
		else
			"zone \"$NAMEZONE\" {
	type master;
	file \"/etc/bind/conf.d/db.$NAMEZONE\";
};" >> /etc/bind/conf.d/named.conf.zones
		fi
		# TODO make sure it does not yet exist?
		touch /etc/bind/conf.d/db.$NAMEZONE
		# make sure it has the right permissions
		chmod 644 /etc/bind/conf.d/db.$NAMEZONE
		# make sure it belongs to bind
		chown bind:bind /etc/bind/conf.d/db.$NAMEZONE
	fi
}

check_dhcp
