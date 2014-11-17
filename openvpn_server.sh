#!/bin/bash

intro()
{
	msgbox "Here you can install and configure OpenVPN to allow access to your local network over a secured internet connection."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to continue?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		install_openvpn
	fi
}

install_openvpn()
{
        if [ `dpkg --list | grep openvpn | grep -v rc | awk '{print $2}' | grep openvpn$ | wc -l` -eq 0  ]; then
                apt-get install -y openvpn
                if [ ! $? -eq 0 ]; then
                        msgbox "Installation failed, please ask for help in forums"
                        return 0
                fi
        fi
	if [ `dpkg --list | grep easy-rsa | grep -v rc | awk '{print $2}' | grep easy-rsa$ | wc -l` -eq 0  ]; then
		apt-get install -y easy-rsa
		if [ ! $? -eq 0 ]; then
			msgbox "Installation failed, please ask for help in forums"
			return 0
		fi
	fi
        configure_openvpn
}

configure_openvpn()
{
	VPNNAME=$(whiptail --backtitle "$TITLE" --title "VPN-Name" --inputbox "Name for the VPN-Configuration:" 0 20 "easy-rsa" 3>&1 1>&2 2>&3)
	cd /etc/openvpn
	if [ $? -eq 0 ] && [ ! -z $VPNNAME ]; then
		KEY_NAME=$VPNNAME
		VPNNAME=`echo $VPNNAME | tr '[:upper:]' '[:lower:]'`
		make-cadir $VPNNAME
	else
		msgbox "Aborting VPN configuration"
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to create a secure configuration (2048 bit keys) or a high secure configuration (4096 bit keys - will take a long time to generate keys)" --yes-button "Secure" --no-button "High Secure" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		KEY_STRENGTH="2048"
	else	
		KEY_STRENGTH="4096"
	fi
	CURRENT_COUNTRY=`grep "export KEY_COUNTRY=" /etc/openvpn/$VPNNAME/vars | sed "s/export KEY_COUNTRY=\"//" | sed "s/\"//"`
	COUNTRY=$(whiptail --backtitle "$TITLE" --title "SSL-Configuration" --inputbox "Country ID (e.g. US, DE, RU, etc.)" 0 20 "$CURRENT_COUNTRY" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$COUNTRY" = "x" ]; then
		CC=$(whiptail --backtitle "$TITLE" --yesno "The Country ID is required, do you really want to abort OpenVPN configuration?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			return 0
		else
			configure_openvpn
			return 0
		fi
	fi
	CURRENT_PROVINCE=`grep "export KEY_PROVINCE=" /etc/openvpn/$VPNNAME/vars | sed "s/export KEY_PROVINCE=\"//" | sed "s/\"//"`
	PROVINCE=$(whiptail --backtitle "$TITLE" --title "SSL-Configuration" --inputbox "Province ID (e.g. CA, DC, FL, etc.)" 0 20 "$CURRENT_PROVINCE" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$PROVINCE" = "x" ]; then
		CC=$(whiptail --backtitle "$TITLE" --yesno "The provoince is required, do you really want to abort OpenVPN configuration?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			return 0
		else
			configure_openvpn
			return 0
		fi
	fi

	CURRENT_CITY=`grep "export KEY_CITY=" /etc/openvpn/$VPNNAME/vars | sed "s/export KEY_CITY=\"//" | sed "s/\"//"`
	CITY=$(whiptail --backtitle "$TITLE" --title "SSL-Configuration" --inputbox "City (e.g. Washington D.C., Berlin, Rom, etc.)" 0 20 "$CURRENT_CITY" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$CITY" = "x" ]; then
		CC=$(whiptail --backtitle "$TITLE" --yesno "The city is required, do you really want to abort OpenVPN configuration?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			return 0
		else
			configure_openvpn
			return 0
		fi
	fi

	CURRENT_ORG=`grep "export KEY_ORG=" /etc/openvpn/$VPNNAME/vars | sed "s/export KEY_ORG=\"//" | sed "s/\"//"`
        ORG=$(whiptail --backtitle "$TITLE" --title "SSL-Configuration" --inputbox "Organization (your company name - used as an identifier)" 0 20 "$CURRENT_ORG" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$ORG" = "x" ]; then
		CC=$(whiptail --backtitle "$TITLE" --yesno "The organization is required, do you really want to abort OpenVPN configuration?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			return 0
		else
			configure_openvpn
			return 0
		fi
	fi

	CURRENT_EMAIL=`grep "export KEY_EMAIL=" /etc/openvpn/$VPNNAME/vars | sed "s/export KEY_EMAIL=\"//" | sed "s/\"//"`
	EMAIL=$(whiptail --backtitle "$TITLE" --title "SSL-Configuration" --inputbox "eMail (your contact eMail)" 0 20 "$CURRENT_EMAIL" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$EMAIL" = "x" ]; then
		CC=$(whiptail --backtitle "$TITLE" --yesno "The email is required, do you really want to abort OpenVPN configuration?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			return 0
		else
			configure_openvpn
			return 0
		fi
	fi

	CURRENT_OU=`grep "export KEY_OU=" /etc/openvpn/$VPNNAME/vars | sed "s/export KEY_OU=\"//" | sed "s/\"//"`
	OU=$(whiptail --backtitle "$TITLE" --title "SSL-Configuration" --inputbox "Organizational Unit" 0 20 "$CURRENT_OU" 3>&1 1>&2 2>&3)
        if [ $? -eq 1 ] || [ "x$OU" = "x" ]; then
		CC=$(whiptail --backtitle "$TITLE" --yesno "The Organizational Unit is required, do you really want to abort OpenVPN configuration?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			return 0
		else
			configure_openvpn
			return 0
		fi
	fi

	# now that we have all data let's write them to the config
	sed -i "s/export KEY_COUNTRY=.*/export KEY_COUNTRY=\"$COUNTRY\"/" /etc/openvpn/$VPNNAME/vars
	sed -i "s/export KEY_PROVINCE=.*/export KEY_PROVINCE=\"$PROVINCE\"/" /etc/openvpn/$VPNNAME/vars
	sed -i "s/export KEY_CITY=.*/export KEY_CITY=\"$CITY\"/" /etc/openvpn/$VPNNAME/vars
	sed -i "s/export KEY_ORG=.*/export KEY_ORG=\"$ORG\"/" /etc/openvpn/$VPNNAME/vars
	sed -i "s/export KEY_EMAIL=.*/export KEY_EMAIL=\"$EMAIL\"/" /etc/openvpn/$VPNNAME/vars
	sed -i "s/export KEY_OU=.*/export KEY_OU=\"$OU\"/" /etc/openvpn/$VPNNAME/vars
	sed -i "s/export KEY_NAME=.*/export KEY_NAME=\"$KEY_NAME\"/" /etc/openvpn/$VPNNAME/vars
	sed -i "s/export KEY_SIZE=.*/export KEY_SIZE=$KEY_STRENGTH/" /etc/openvpn/$VPNNAME/vars

	# now let's be paranoid and go to higher security
	sed -i "s/^default_md.*/default_md		= sha512/" /etc/openvpn/$VPNNAME/openssl-1.0.0.cnf 

	# check some pre-requirements
	[ -d /etc/openvpn/$VPNNAME/keys ] || mkdir -p /etc/openvpn/$VPNNAME/keys
	[ -f /etc/openvpn/$VPNNAME/keys/index.txt ] || touch /etc/openvpn/$VPNNAME/keys/index.txt
	[ -f /etc/openvpn/$VPNNAME/keys/serial ] || echo 01 > /etc/openvpn/$VPNNAME/keys/serial

	# load config
	cd /etc/openvpn/$VPNNAME/
	. ./vars # load environment variables
	./clean-all # remove everything -> TODO check if we already have something here and ask if clean-all?
	
	# create new CA
	./build-ca
	
	# create server certificate
	HOST=$(whiptail --backtitle "$TITLE" --title "Server Name" --inputbox "Name of the VPN-Server (for example dyndns name)" 0 20 "`hostname`" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ] && [ "x$HOST" != "x" ]; then
		./build-key-server $HOST
	else
		./build-key-server `hostname`
	fi
	# Generate BUILD DIFFIE-HELLMAN PARAMETERS (necessary for the server end of a SSL/TLS connection)
	./build-dh
	
	# generate config
	# TODO ask for network instead of taking 10.9.8.0/24  
	echo "port 1194
proto udp
dev tun

ca		/etc/openvpn/$VPNNAME/keys/ca.crt	# generated keys
cert		/etc/openvpn/$VPNNAME/keys/${HOST}.crt
key		/etc/openvpn/$VPNNAME/keys/${HOST}.key	# keep secret
dh		/etc/openvpn/$VPNNAME/keys/dh${KEY_STRENGTH}.pem
#crl-verify	/etc/openvpn/$VPNNAME/keys/crl.pem

server 10.9.8.0 255.255.255.0  # internal tun0 connection IP
ifconfig-pool-persist /etc/openvpn/$VPNNAME/ipp.txt
client-to-client
cipher AES-192-CBC	# AES
user nobody
group nogroup
keepalive 10 120
comp-lzo	# Compression - must be turned on at both end
persist-key
persist-tun
status /etc/openvpn/$VPNNAME/openvpn-status.log
verb 4	# verbose mode
# work around for mtu-size-limitation
mssfix 1200" > /etc/openvpn/$VPNNAME/server.conf
	ln -sf /etc/openvpn/$VPNNAME/server.conf /etc/openvpn/${VPNNAME}.conf
	# we need to push a network to the VPN
	VPNSERVER_NETWORK=$(whiptail --backtitle "$TITLE" --title "Local Network to be used for VPN-Server" --inputbox "What's the local network (and netmask) that should be used through the VPN? (for example: 192.168.123.0 255.255.255.0)" 0 20 "192.168.123.0 255.255.255.0" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		msgbox "You didn't use a local network for your VPN."
	fi
	if [ "x$VPNSERVER_NETWORK" != "x" ]; then
		echo "push \"route $VPNSERVER_NETWORK\"" >> /etc/openvpn/$VPNNAME/server.conf
	fi
	# create client configuration template
	VPNSERVER_IP=$(whiptail --backtitle "$TITLE" --title "IP of VPN-Server" --inputbox "IP address to connect to the VPN Server (external IP address or dyndns)" 0 20 "myserver.example.com" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		msgbox "VPN Server IP is required, using 127.0.0.1 for now, please adapt /etc/openvpn/$VPNNAME/client.conf manually."
		VPNSERVER_IP="127.0.0.1"
	fi
	echo "client
dev tun
port 1194
proto udp

remote $VPNSERVER_IP 1194		# VPN server IP : PORT
nobind

ca ca.crt
cert %%CLIENT_NAME%%.crt
key %%CLIENT_NAME%%.key

comp-lzo
persist-key
persist-tun
# Select a cryptographic cipher.
cipher AES-192-CBC        # AES
# Set log file verbosity.
verb 3" > /etc/openvpn/$VPNNAME/client.conf
	
	# create empty revocation list
	[ -f /etc/openvpn/$VPNNAME/keys/crl.pem ] || touch /etc/openvpn/$VPNNAME/keys/crl.pem 
	
	# create log folder and log file if not yet exist
	[ -f /etc/openvpn/$VPNNAME/openvpn-status.log ] || touch /etc/openvpn/$VPNNAME/openvpn-status.log

	# restart OpenVPN and hope it's working
	service openvpn restart
}

intro
