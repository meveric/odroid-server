#!/bin/bash

intro()
{
	msgbox "Here you can create new client certificates for your OpenVPN Server."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to continue?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		select_vpn
	fi
}

select_vpn()
{
	OPTIONS=""
	cd /etc/openvpn
	NUM_FOLDERS=`find . -maxdepth 1 -type d | sed "1d" | sed "s/\.//" | sed "s/\///" | wc -l`
	i=0
	for folders in `find . -maxdepth 1 -type d | sed "1d" | sed "s/\.//" | sed "s/\///"`
	do
		OPTIONS="$folders	$(($NUM_FOLDERS-$i))
$OPTIONS"
		i=$(($i+1))
	done
	VPN=$(whiptail --backtitle "$TITLE" --menu "Select VPN to create client certificates for" 0 0 1 \
		$OPTIONS \
		3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		cd /etc/openvpn/$VPN
		# import variables
		. ./vars
	else
		return 0
	fi
	create_client_certificate
}

create_client_certificate()
{
	CLIENT_NAME=$(whiptail --backtitle "$TITLE" --title "Client Name" --inputbox "Name of the VPN client (e.g. hostname of the client)" 0 20 "pc-client-1" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ] && [ "x$CLIENT_NAME" != "x" ]; then
		./build-key $CLIENT_NAME
	else
		return 0
	fi
	# only when last command was sucessful
	if [ $? -eq 0 ]; then
		VPNSERVER_IP=$(whiptail --backtitle "$TITLE" --title "IP of VPN-Server" --inputbox "IP address to connect to the VPN Server (external IP address or dyndns)" 0 20 "myserver.example.com" 3>&1 1>&2 2>&3)
		# TODO check if an IP was entered and is valid
		if [ $? -eq 1 ]; then
			return 0
		fi
		echo "client
dev tun
port 1194
proto udp

remote $VPNSERVER_IP 1194             # VPN server IP : PORT
nobind

ca ca.crt
cert ${CLIENT_NAME}.crt
key ${CLIENT_NAME}.key

comp-lzo
persist-key
persist-tun
# Select a cryptographic cipher.
cipher AES-192-CBC        # AES
# Set log file verbosity.
verb 3" > /etc/openvpn/$VPN/keys/${CLIENT_NAME}.ovpn
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to create another client certificate for $VPN?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		create_client_certificate
		return 0
	else
		return 0
	fi	
}

intro
