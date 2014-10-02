#!/bin/bash

intro()
{
	msgbox "With a DHCP Server your server can distribute IP addresses dynamically to clients in the network and distribut informations such as Router and DNS server for all client."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a DHCP Server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		check_network_adapters
	fi
}


check_network_adapters()
{
	adapter=`. $HOMEDIR/get_network_adapters.sh`
	check_dhcp
}

# check if we get our IP over DHCP
check_dhcp()
{
	if [ `cat /etc/network/interfaces | grep "iface $adapter" | grep dhcp | wc -l` -ge 1 ]; then
		# dhcp is still active but we need a static IP address in order to do activate DHCP server
		CC=$(whiptail --backtitle "$TITLE" --yesno "You don't have a static IP address, but we need this to setup the DHCP server.
Do you want to setup a static IP address now?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			. $HOMEDIR/change_ip.sh static $adapter
		else
			msgbox "DHCP Server can't be configured without a static IP address.
Also you should deactivate other DHCP servers (such as other routers) on the same network in order to avoid conflicts between the different DHCP servers."
			return 0
		fi
	fi
	install_dhcp_server
}
# install dhcp-server if not yet intalled
install_dhcp_server()
{
	if [ `dpkg --list | grep isc-dhcp-server | wc -l` -lt 1 ] || [ `dpkg --list | grep isc-dhcp-server | grep rc | wc -l` -eq 1  ]; then
		apt-get install -y isc-dhcp-server
		if [ ! $? -eq 0 ]; then
			msgbox "Installation failed, please ask for help in forums"
			return 0
		fi
	fi
	configure_dhcp_server
}

# basic configuration of different subnet for dhcp client
# TODO
# - allow reconfigre of existing subnets
# - sainity checks for different subnets (very huge task)
# - adding single devices with static IP if wanted
configure_dhcp_server()
{
	if [ ! -d /etc/dhcp/conf.d/ ]; then
		mkdir /etc/dhcp/conf.d
	fi
	NUM_CONFIG=`ls /etc/dhcp/conf.d/ | wc -l`
	msgbox "We are now going to setup a basic configuration.
This includes options like what's the router for each client, what's the DNS server, what's the IP range for your clients."
	msgbox "Please enter the Network-IP of your subnet for your DHCP server.
For example 192.168.0.0.
The DHCP server does not have to be part of that subnet."
	CURRENT_IP=`ifconfig | grep -n1 $adapter | grep "inet addr:" | cut -d ":" -f2 | cut -d " " -f1`
	NETWORK_ADDRESS="`echo $CURRENT_IP | cut -d '.' -f1`.`echo $CURRENT_IP | cut -d '.' -f2`.`echo $CURRENT_IP | cut -d '.' -f3`.0"
	SUBNET=$(whiptail --backtitle "$TITLE" --title "Subnet Network IP Address" --inputbox "IP-Address" 0 20 "$NETWORK_ADDRESS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	# if Exit then go back to menu
	if [ $? -eq 1 ]; then
		return 0
	fi
	if [ -z $SUBNET ]; then
		msgbox "The network address is very important and a must have for a DHCP server if you are unsure on how to do it please ask in the forums."
		. $HOMEDIR/dhcp_server.sh
	fi
	msgbox "Please enter a netmask for your subnet.
A Subnet defines what machines can see each other in that subnet and how many fit in a certain network.
A good choise for example is 255.255.255.0"
	# if Exit then go back to menu
	if [ $? -eq 1 ]; then
		return 0
	fi
	CURRENT_NETMASK=`ifconfig | grep -n1 $adapter | grep "Mask:" | cut -d ":" -f4`
	NETMASK=$(whiptail --backtitle "$TITLE" --title "Subnetmask" --inputbox "Netmask" 0 20 "$CURRENT_NETMASK" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ -z $NETMASK ]; then
		msgbox "The subnetmask is very important and a must have for a DHCP server if you are unsure on how to do it please ask in the forums."
		. $HOMEDIR/dhcp_server.sh
		return 0
	fi
	msgbox "Please enter the gateway IP-Address.
A gateway (or router) is used to connect to different networks (for example to get from the local network to the internet)
It should look like 192.168.0.1"
	# if Exit then go back to menu
	if [ $? -eq 1 ]; then
		return 0
	fi
	CURRENT_GATEWAY=`route -n  | grep ^0.0.0.0 | awk '{print $2}'`
	GATEWAY=$(whiptail --backtitle "$TITLE" --title "Gateway Server" --inputbox "Gateway Server (Router-IP)" 0 20 "$CURRENT_GATEWAY" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	# if Exit then go back to menu
	if [ $? -eq 1 ]; then
		return 0
	fi
	msgbox "Please enter the DNS server used to resolve names for this subnet.
This can for example be the router, or a different DNS server if necessary.
It should look like 192.168.0.1"
	CURRENT_DNS=`cat /etc/resolv.conf  | grep ^nameserver | head -n 1 | awk '{print $2}'`
	DNS=$(whiptail --backtitle "$TITLE" --inputbox "DNS Server (separate multiple DNS by space)" 0 20 "$CURRENT_DNS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	# if Exit then go back to menu
	if [ $? -eq 1 ]; then
		return 0
	fi
	msgbox "Please enter the Search Domain.
The search domain is used to quickly find machines in one network (domain)
for example if your domain is \"mydomain.home\" and the device name is called \"odroid-server\" the FQDN (Fully Qualified Domain Name) would be \"odroid-server.mydomain.home\"
In order to not have to write the entire name you can define a search domain called \"mydomain.home\" and whenever you search for \"odroid-server\" it will automaticaly add \".mydomain.home\" to seach for machines."
	CURRENT_SEARCH=`cat /etc/resolv.conf  | grep ^search | head -n 1 | awk '{print $2}'`
	DOMAIN=$(whiptail --backtitle "$TITLE" --inputbox "Search Domain" 0 20 "$CURRENT_SEARCH" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	# if Exit then go back to menu
	if [ $? -eq 1 ]; then
		return 0
	fi
	msgbox "Please select an IP-Range.
The IP-Range defines in what range the DHCP server should distribute IP-Addresses to the clients.
For example: 192.168.0.100 192.168.0.200 (to disribute IPs from 192.168.0.100 to 192.168.0.199 -> 100 IP-Addresses for clients
Please make sure not to use more then fit in your subnet."
	CURRENT_IP=`ifconfig | grep -n1 $adapter | grep "inet addr:" | cut -d ":" -f2 | cut -d " " -f1`
	IPRANGE="`echo $CURRENT_IP | cut -d '.' -f1`.`echo $CURRENT_IP | cut -d '.' -f2`.`echo $CURRENT_IP | cut -d '.' -f3`.100 `echo $CURRENT_IP | cut -d '.' -f1`.`echo $CURRENT_IP | cut -d '.' -f2`.`echo $CURRENT_IP | cut -d '.' -f3`.199"
	DHCP_RANGE=$(whiptail --backtitle "$TITLE" --title "Subnet IP-Range" --inputbox "IP-Range" 0 40 "$IPRANGE" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	# if Exit then go back to menu
	if [ $? -eq 1 ]; then
		return 0
	fi
	if [ -z $DHCP_RANGE ]; then
		msgbox "The IP-Range is very important and a must have for a DHCP server if you are unsure on how to do it please ask in the forums."
		. $HOMEDIR/dhcp_server.sh
		return 0	
	fi
	
	# writing new config file
	echo "subnet $SUBNET netmask $NETMASK {
# RANGE START
	range $DHCP_RANGE;
# RANGE END" > /etc/dhcp/conf.d/config.$NUM_CONFIG
	if [ ! -z $GATEWAY ]; then
		echo "# ROUTER START
	option routers $GATEWAY;
# ROUTER END" >> /etc/dhcp/conf.d/config.$NUM_CONFIG
	fi
	if [ ! -z $DNS ]; then
		echo "# DNS START
	option domain-name-servers $DNS;
# DNS END" >> /etc/dhcp/conf.d/config.$NUM_CONFIG
	fi
	if [ ! -z $DOMAIN ]; then
		echo "# DOMAIN START
	option domain-name \"$DOMAIN\";
# DOMAIN END" >> /etc/dhcp/conf.d/config.$NUM_CONFIG
	fi
	echo "}" >> /etc/dhcp/conf.d/config.$NUM_CONFIG
	# add new config file in dhcpd.conf
	echo "include \"/etc/dhcp/conf.d/config.$NUM_CONFIG\";" >> /etc/dhcp/dhcpd.conf
	# make sure dhcp runs on $adapter
	sed -i "s/^INTERFACES.*/INTERFACES=\"$adapter\"/" /etc/default/isc-dhcp-server
	# restart dhcp server
	service isc-dhcp-server restart
	if [ $? -ne 0 ]; then
		msgbox "An error occurred while restarting the DHCP server (probably cause of some misconfiguration)
please check server logs /var/log/syslog for more information and try to fix the issues.
The correspondig config file can be found in: /etc/dhcp/conf.d/config.$NUM_CONFIG"
	fi
}

intro
