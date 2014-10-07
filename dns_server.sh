#!/bin/bash
# DNS-Server (Bind) installation and configuration

intro()
{
	msgbox "With a DNS Server your server can resolve names to certain IP addresses and vice versa. It can be used to register all your clients in the Network under their name and make them them known to each other under their names rather then their IP address."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a DNS Server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		check_network_adapters
	fi
}

check_network_adapters()
{
	adapter=`. $HOMEDIR/get_network_adapters.sh`
	check_dhcp
}

# check if we run on DHCP or static IP
check_dhcp()
{
	# check if adater is set on static IP needed for DNS Server
	if [ `cat /etc/network/interfaces | grep "iface $adapter" | grep dhcp | wc -l` -ge 1 ] || [ `cat /etc/network/interfaces | grep "iface $adapter" | wc -l` -lt 1 ]; then
		# dhcp is still active but we need a static IP address in order to do activate DHCP server
		CC=$(whiptail --backtitle "$TITLE" --yesno "You don't have a static IP address, but we need this to setup the DNS server.
Do you want to setup a static IP address now?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			. $HOMEDIR/change_ip.sh static $adapter
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
	# just for later use we make sure the rndc.key is included
	if [ `cat /etc/bind/named.conf.local | grep rndc.key | wc -l` -lt 1 ]; then
		echo "include \"/etc/bind/rndc.key\";" >> /etc/bind/named.conf.local
		# allow dynamic DNS updates
		echo "controls { inet 127.0.0.1 allow { localhost; } keys { "rndc-key"; }; };" >> /etc/bind/named.conf.local
	fi
	# TODO check if forwarder is already configured
	if [ `cat /etc/bind/named.conf.options | grep forwarders | grep -v // | wc -l` -ge 1 ]; then
		# do crazy stuff with it
		# TODO backup old forwarder and incorporate in new config file if not yet exist
		msgbox "You already have preconfigured bind server, which is not supported right now."
		return 0
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
		FORWARDER=$(whiptail --backtitle "$TITLE" --title "DNS-Forwareder" --inputbox "IP-Address for DNS forwarding" 0 20 "$CURRENT_DNS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
		if [ ! -f /etc/bind/conf.d/named.conf.options ]; then
			if [ ! -z $FORWARDER ]; then
				echo "options {
	forwarders {
		$FORWARDER;
	};
};" > /etc/bind/conf.d/named.conf.options
		else
			# TODO check if forwarder already exist or should be added, or replace old
			continue
		fi
		# deactivating old options
		sed -i "s/^include \"\/etc\/bind\/named.conf.options\";/\/\/ include \"\/etc\/bind\/named.conf.options\";/" "/etc/bind/named.conf" "/etc/bind/named.conf"
			if [ `cat /etc/bind/named.conf | grep /etc/bind/conf.d/named.conf.options | wc -l` -lt 1 ]; then
				echo "include \"/etc/bind/conf.d/named.conf.options\";" >> /etc/bind/named.conf
			fi
		fi
	fi
	# TODO check for existing namezones? -> call advanced configuration
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to create a new namezone?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		CURRENT_SEARCH=`cat /etc/resolv.conf  | grep ^search | head -n 1 | awk '{print $2}'`
		NAMEZONE=$(whiptail --backtitle "$TITLE" --inputbox "New NameZone" 0 20 "$CURRENT_SEARCH" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
		if [ ! -f /etc/bind/conf.d/named.conf.zones ]; then
			echo "zone \"$NAMEZONE\" {
	type master;
	file \"/etc/bind/conf.d/db.$NAMEZONE\";
	allow-update { key rndc-key; };
};" > /etc/bind/conf.d/named.conf.zones
		elif [ `cat /etc/bind/conf.d/named.conf.zones | grep "zone \"$NAMEZONE\" {" | wc -l` -eq 0 ]; then
			"zone \"$NAMEZONE\" {
	type master;
	file \"/etc/bind/conf.d/db.$NAMEZONE\";
	allow-update { key rndc-key; };
};" >> /etc/bind/conf.d/named.conf.zones
		else
			msgbox "You already have a zone called \"$NAMEZONE\"!"
			return 0
		fi
		# TODO make sure it does not yet exist? - should not be necessary since it was checked previous
		CURRENT_IP=`ifconfig | grep -n1 $adapter | grep "inet addr:" | cut -d ":" -f2 | cut -d " " -f1`
		echo "\$TTL    86400
$NAMEZONE.       IN      SOA     $HOSTNAME.$NAMEZONE. root.$HOSTNAME.$NAMEZONE. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      $HOSTNAME.$NAMEZONE.
$HOSTNAME	IN	A	$CURRENT_IP" > /etc/bind/conf.d/db.$NAMEZONE

		# make sure it has the right permissions
		chmod 644 /etc/bind/conf.d/db.$NAMEZONE
		# make sure it belongs to bind
		chown bind:bind /etc/bind/conf.d/db.$NAMEZONE
		# make sure our new zones are getting loaded
		if [ `cat /etc/bind/named.conf | grep /etc/bind/conf.d/named.conf.zones | wc -l` -lt 1 ]; then
			echo "include \"/etc/bind/conf.d/named.conf.zones\";" >> /etc/bind/named.conf
		fi
		CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to create a reverse lookup for the ZONE $NAMEZONE?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			# check for netmask
			CURRENT_NETMASK=`ifconfig | grep -n1 $adapter | grep "Mask:" | cut -d ":" -f4`
			# TODO calculate network to corresponding netmask and IP-Address
			INARPA="`echo $CURRENT_IP | cut -d '.' -f3`.`echo $CURRENT_IP | cut -d '.' -f2`.`echo $CURRENT_IP | cut -d '.' -f1`.in-addr.arpa"
			PTR="`echo $CURRENT_IP | cut -d '.' -f4`"
			if [ `cat /etc/bind/conf.d/named.conf.zones | grep "zone \"$INARPA\" {" | wc -l` -eq 0 ]; then
				echo "zone \"$INARPA\" {
	type master;
	file \"/etc/bind/conf.d/db.$INARPA\";
	allow-update { key rndc-key; };
};" >> /etc/bind/conf.d/named.conf.zones
			echo "\$TTL    86400
$INARPA.       IN      SOA     $HOSTNAME.$NAMEZONE. root.$HOSTNAME.$NAMEZONE. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      $HOSTNAME.$NAMEZONE.
$PTR	IN	PTR	$HOSTNAME.$NAMEZONE." > /etc/bind/conf.d/db.$INARPA
				# make sure it has the right permissions
				chmod 644 /etc/bind/conf.d/db.$INARPA
				# make sure it belongs to bind
				chown bind:bind /etc/bind/conf.d/db.$INARPA
			else
				msgbox "You already have a reverse lookup zone for \"$NAMEZONE\"!"
				return 0
			fi
		fi
		# TODO dynamic DNS over DHCP?
	fi
	# restart DNS Server to load new settings
	service bind9 restart
}

intro
