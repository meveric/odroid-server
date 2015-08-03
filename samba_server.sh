#!/bin/bash
intro()
{
	msgbox "With a Samba Server you can share files and folder in your network similar as under windows.
This installation will only activate basic shared folder capabilities and will not allow you to configure domains."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a Samba Server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		# do some crazy stuff
		install_samba
		return 0	
	fi
}

install_samba()
{
	get_updates
	apt-get install -y samba
	if [ ! $? -eq 0 ]; then
		msgbox "Installation failed, please ask for help in forums"
		return 0
	fi
	configure_samba
}

configure_samba()
{
	# backup original smb.conf
	if [ ! -f /etc/samba/smb.conf.bak ]; then
		mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
	fi
	# create "clean" smb.conf
	if [ ! -f /etc/samba/smb.conf ]; then
		testparm -s /etc/samba/smb.conf.bak > /etc/samba/smb.conf
	fi
	
	# home directories
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to enable home folders for your Samba server users (in /home/)?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		# check if entry already exist
		if [ `grep "\[homes\]" /etc/samba/smb.conf | wc -l` -ge 1 ]; then
			msgbox "Homes definition in smb.conf already found. Please use advanced configuration to reconfigure."
		else
			echo "[homes]
	comment = Home Directories
	browseable = no
	valid users = %S
	writeable = yes
	create mode = 0600
	directory mode = 0700" >> /etc/samba/smb.conf
		fi
	fi
	restart_server
}

restart_server()
{
	if [ ! -f /var/lib/samba/private/secrets.tdb ]; then
		mkdir -p /var/lib/samba/private
		touch /var/lib/samba/private/secrets.tdb
	fi
	service smbd restart
	if [ $? -eq 0 ]; then
		msgbox "Samba server installed and configured correctly and is now running. Use advanced configuration to create and remove shares."
		msgbox "PLEASE NOTE:
You need to create a samba user to connect to a samba server. Please use the advanced samba server configuration to create a user."
	else
		msgbox "Something went wrong during start of your samba server. Please check log files and ask for help on the forums."
	fi
}

intro
