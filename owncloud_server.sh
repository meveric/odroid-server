#!/bin/bash
intro()
{
	msgbox "With OwnCloud you can create your own personal Cloud Server similar to Dropbox to store and organize your files and sync them between devices, all while having complete control over your files and not giving your files to a third party."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a Linux Dash now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		install_owncloud
	fi
}

install_owncloud()
{
	get_updates
	if [ ! -f /etc/apt/sources.list.d/owncloud.list ]; then
		echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_14.04/ /' >> /etc/apt/sources.list.d/owncloud.list
		wget -O- http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_14.04/Release.key | apt-key add -
		apt-get update
	fi
	apt-get install -y owncloud
	if [ $? -ne 0 ]; then
		msgbox "Something went wrong during installation."
		return 0
	fi
	# fixing some permission issues
	chown -R www-data:www-data /var/www/owncloud
	# configure?
#	configure_owncloud
	start_server
}

configure_owncloud()
{
	return 0
}

start_server()
{
	service apache2 restart
	if [ $? -ne 0 ]; then
		msgbox "Can't start apache2 server, please check logs."
		return 0
	else
		msgbox "OwnCloud installed. Direct your browser to http://`hostname`/owncloud to finish setup"
	fi
	return 0
}

intro
