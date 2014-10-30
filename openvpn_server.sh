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
	cd /etc/openvpn
	make-cadir easy-rsa
	CURRENT_COUNTRY=`grep "export KEY_COUNTRY=" /etc/openvpn/easy-rsa/vars | sed "s/export KEY_COUNTRY=\"//" | sed "s/\"//"`
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
	CURRENT_PROVINCE=`grep "export KEY_PROVINCE=" /etc/openvpn/easy-rsa/vars | sed "s/export KEY_PROVINCE=\"//" | sed "s/\"//"`
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

	CURRENT_CITY=`grep "export KEY_CITY=" /etc/openvpn/easy-rsa/vars | sed "s/export KEY_CITY=\"//" | sed "s/\"//"`
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

	CURRENT_ORG=`grep "export KEY_ORG=" /etc/openvpn/easy-rsa/vars | sed "s/export KEY_ORG=\"//" | sed "s/\"//"`
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

	CURRENT_EMAIL=`grep "export KEY_EMAIL=" /etc/openvpn/easy-rsa/vars | sed "s/export KEY_EMAIL=\"//" | sed "s/\"//"`
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

	CURRENT_OU=`grep "export KEY_OU=" /etc/openvpn/easy-rsa/vars | sed "s/export KEY_OU=\"//" | sed "s/\"//"`
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
	sed -i "s/export KEY_COUNTRY=.*/export KEY_COUNTRY=\"$COUNTRY\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_PROVINCE=.*/export KEY_PROVINCE=\"$PROVINCE\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_CITY=.*/export KEY_CITY=\"$CITY\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_ORG=.*/export KEY_ORG=\"$ORG\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_EMAIL=.*/export KEY_EMAIL=\"$EMAIL\"/" /etc/openvpn/easy-rsa/vars
	sed -i "s/export KEY_OU=.*/export KEY_OU=\"$OU\"/" /etc/openvpn/easy-rsa/vars

	# TODO
	# ask for KEY_SIZE=2048 or KEY_SIZE=4096 (higher values as 2048 might not be supported by mobile devices)

	# now let's be paranoid and go to higher security
	sed -i "s/^default_md.*/default_md		= sha512/"

	echo "WIP"
}

intro
