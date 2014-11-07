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
		msgbox "You've been ask to add \"extra\" attributes, please choose a secure password here to prevent other people to use your certificate without authorization"
		./build-key $CLIENT_NAME
	else
		return 0
	fi
	# create client config file
	cp /etc/openvpn/$VPN/client.conf /etc/openvpn/$VPN/keys/${CLIENT_NAME}.ovpn
	sed -i "s/%%CLIENT_NAME%%/$CLIENT_NAME/" /etc/openvpn/$VPN/keys/${CLIENT_NAME}.ovpn
	msgbox "Your client certificate has been stored under /etc/openvpn/$VPN/keys/$CLIENT_NAME the following files are needed for the client:
ca.crt                  # Server CA file
${CLIENT_NAME}.crt      # client certificate
${CLIENT_NAME}.key      # private key file (should kept secret)
${CLIENT_NAME}.ovpn     # OpenVPN configuration file for OpenVPN clients"
	mkdir -p /etc/openvpn/$VPN/keys/$CLIENT_NAME
	cp /etc/openvpn/$VPN/keys/ca.crt /etc/openvpn/$VPN/keys/${CLIENT_NAME}.crt /etc/openvpn/$VPN/keys/${CLIENT_NAME}.key /etc/openvpn/$VPN/keys/${CLIENT_NAME}.ovpn /etc/openvpn/$VPN/keys/${CLIENT_NAME}/
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to create another client certificate for $VPN?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		create_client_certificate
		return 0
	else
		return 0
	fi	
}

intro
