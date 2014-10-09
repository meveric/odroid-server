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
	get_updates
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
	if [ `dpkg --list | grep smbclient | grep -v rc | awk '{print $2}' | grep smbclient$ | wc -l` -eq 0  ]; then
		apt-get install -y smbclient
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
	if [ `apt-cache policy bind9 | grep Installed | grep none | wc -l` -ne 1 ]; then
		msgbox "bind9 was found installed on your system but for now we can't use bind9 together with samba4 AD together so it has to be removed."
		CC=$(whiptail --backtitle "$TITLE" --title "Bind9 Server found" --yesno "Do you want to remove bind9 now?" 0 20  0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ]; then
			msgbox "setup can not be completed with bind9 installed, returning to menu"
			return 0
		else
			apt-get -y autoremove bind9
		fi
	fi
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
	# remove old smb.conf -> we will create backup
	# create backup only if not already exist, delete instead
	if [ ! -f /etc/samba/smb.conf.bak ]; then
		mv /etc/samba/smb.conf{,.bak}
	else
		rm -f /etc/samba/smb.conf
	fi
	samba-tool domain provision --use-rfc2307 --realm=$REALM --domain=$DOMAIN --adminpass=$PASSWORD --dns-backend=$DNS_BACKEND --server-role=dc --option="interfaces=$adapter" --option="bind interfaces only=yes" --use-ntvfs
	ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf
	# fixing issue with upstart
	cat <<\EOF > /etc/init/samba-ad-dc.conf
description "SMB/CIFS File and Active Directory Server"
author      "Jelmer Vernooij <jelmer@ubuntu.com>"

start on (local-filesystems and net-device-up)
stop on runlevel [!2345]

expect fork
normal exit 0

pre-start script
        [ -r /etc/default/samba4 ] && . /etc/default/samba4
        install -o root -g root -m 755 -d /var/run/samba
        install -o root -g root -m 755 -d /var/log/samba
end script

exec samba -D
EOF
	if [ "x$FORWARDER" != "x" ]; then
		# TODO configure /etc/smb.conf with dns forwarder = $FORWARDER
		sed -i "s/dns forwarder.*/dns forwarder = $FORWARDER/" "/etc/samba/smb.conf"
	fi
	start_and_do_checks
}

start_and_do_checks()
{
	# make sure samba does not run
	killall samba
	sleep 2
	# start samba
	samba -D
	sleep 2
	# do first tests:
	CURRENT_IP=`ifconfig | grep -n1 $adapter | grep "inet addr:" | cut -d ":" -f2 | cut -d " " -f1`
	NETLOGON=`smbclient -L $CURRENT_IP -U% | grep netlogon | wc -l`
	SYSVOL=`smbclient -L $CURRENT_IP -U% | grep sysvol | wc -l`
	if [ $NETLOGON -eq 1 ] && [ $SYSVOL -eq 1 ]; then
		msgbox "Anonymous login successful, netlogon and sysvol found"
	else
		msgbox "Something unexpected has happend and samba is not working correctly. Anonymous login failed."
		return 0
	fi
	# do logon test:
	LOGIN=`smbclient //$CURRENT_IP/netlogon -UAdministrator -c 'ls' -P $PASSWORD | wc -l`
	if [ $LOGIN -ge 4 ]; then
		msgbox "Login as Administrator successful"
	else
		msgbox "Something unexpected has happend and samba is not working correctly. Login as Administrator failed."
		return 0
	fi
	# check DNS entry for LDAP
	HOSTNAME=`hostname`
	if [ `dig @$CURRENT_IP -t SRV _ldap._tcp.$REALM\. | grep -i "0 100 389 $HOSTNAME\.$REALM\." | wc -l` -eq 1 ]; then
		msgbox "DNS entry for LDAP found"
	else
		msgbox "Something unexpected has happend and samba is not working correctly. DNS entry for LDAP could not be found."
		return 0
	fi
	# check DNS entry for Kerberos
	if [ `dig @$CURRENT_IP -t SRV _kerberos._udp.$REALM\. | grep -i "0 100 88 $HOSTNAME\.$REALM\." | wc -l` -eq 1 ]; then
		msgbox "DNS entry for Kerberos found"
	else
		msgbox "Something unexpected has happend and samba is not working correctly. DNS entry for Kerberos could not be found."
		return 0
	fi
	# check DNS entry for host FQDN
	if [ `dig @$CURRENT_IP -t A $HOSTNAME\.$REALM\. | grep IN | grep A | grep $CURRENT_IP | wc -l` -eq 1 ]; then
		msgbox "DNS entry for $HOSTNAME.$REALM found"
	else
		msgbox "Something unexpected has happend and samba is not working correctly. DNS entry for $HOSTNAME.$REALM could not be found."
		return 0
	fi
	# skipping kinit for now
#	mv /etc/resolv.conf{,.bak}
#	echo "nameserver $CURRENT_IP" > /etc/resolv.conf
#	kinit administrator@$REALM 

	msgbox "All test successful your Samba Active Directory Domain is up and running make sure to use $CURRENT_IP for clients as a DNS Server"
}

intro
