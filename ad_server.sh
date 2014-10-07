#!/bin/bash
intro()
{
	msgbox "With a Samba Active Directory Domain you can create a Active Directory similar to MicroSoft Active Directory. In fact it was meant as a free reimplementation of MicroSoft Active Directory and allows you to organize your Linux and Windows Machines in a Active Directory environment. Which can be configured and managed with the same tools a Windows Active Directory Domain can be."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a Samba Active Directory now?" 0 0 3>&1 1>&2 2>&3)
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
		CC=$(whiptail --backtitle "$TITLE" --yesno "You don't have a static IP address, but we need this to setup the Samba Active Directory Domain Server.
Do you want to setup a static IP address now?" 0 0 3>&1 1>&2 2>&3)
                if [ $? -eq 0 ]; then
                        . $HOMEDIR/change_ip.sh static $adapter
                else
                        msgbox "Samba Active Directory Domain Server can't be configured without a static IP address."
                        return 0
                fi
        fi
        install_ad_server
}

install_ad_server()
{
	if [ `dpkg --list | grep samba | grep -v rc | awk '{print $2}' | grep samba$ | wc -l` -eq 0  ]; then
		apt-get install -y samba
		if [ ! $? -eq 0 ]; then
			msgbox "Installation failed, please ask for help in forums"
			return 0
		fi
	fi
	if [ `dpkg --list | grep ntp | grep -v rc | awk '{print $2}' | grep ntp$ | wc -l` -eq 0  ]; then
		apt-get install -y ntp
		if [ ! $? -eq 0 ]; then
			msgbox "Installation failed, please ask for help in forums"
			return 0
		fi
	fi
	configure_ad_server
}

configure_ad_server()
{
	REALM=$(whiptail --backtitle "$TITLE" --title "AD Realm" --inputbox "Please enter the Realm Name of your new AD Domain (e.g. SAMDOM.EXAMPLE.COM)" 0 20  --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		msgbox "Realm name is required in order to setup an Active Directory Domain."
		return 0
	fi
	if [ `echo $REALM | grep "\."` -lt 1 ]; then
		msgbox "The Realm needs at least one \"dot\" in the name to work properly. Good examples would be .lan or .home or something similar"
		configure_ad_server
		return 0
	fi
	REALM=`echo $REALM | tr [:lower:] [:upper:]`
	DOMAIN=`echo $REALM | cut -d "." -f1`
	CC=$(whiptail --backtitle "$TITLE" --title "AD Domain Name" --yesno "Your new Domain will be named $DOMAIN, is this correct?" 0 20  0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		configure_ad_server
		return 0
	fi
	# define SAMBA internal as DNS Server for now.
	# TODO add option to use Bind9 instead
	DNS_BACKEND="SAMBA_INTERNAL"
	CURRENT_DNS=`cat /etc/resolv.conf  | grep ^nameserver | head -n 1 | awk '{print $2}'`
	FORWARDER=$(whiptail --backtitle "$TITLE" --title "DNS-Forwareder" --inputbox "IP-Address for DNS forwarding (e.g. Router IP)" 0 20 "$CURRENT_DNS" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	PASSWORD=$(whiptail --backtitle "$TITLE" --title "Administrator Password" --passwordbox "Define a password for the Administrator user of the Active Directory Domain 
please make sure to fulfill the security requirements:
min. 8 letters, small and big letters and at least one number and/or special character 
hit enter for default password" 0 20 --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ -z $PASSWORD ]; then
		PASSWORD="Pa\$\$w0rd"
		msgbox "No password entered - default password: \"Pa\$\$w0rd\""
	fi
	OPTIONS="--use-rfc2307 --domain=$DOMAIN --adminpass=$PASSWORD --dns-backend=$DNS_BACKEND --server-role=dc --option=\"interfaces=$adapter\" --option=\"bind interfaces only=yes\""
	samba-tool domain provision $OPTIONS
	if [ "x$FORWARDER" = "x" ]; then
		# TODO configure /etc/smb.conf with dns forwarder = $FORWARDER
		continue
	fi
}

intro
