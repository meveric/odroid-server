#!/bin/bash
intro()
{
	msgbox "With Linux Dash you can monitor your computer and check on system information such as RAM usage, system load, network status and more. It uses a WebServer (apache2) to present the data. Check https://github.com/linux-dash/linux-dash for more details."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a Linux Dash now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		install_linux_dash
	fi
}

install_linux_dash()
{
	get_updates
	apt-get install -y apache2 php5-json php5
	if [ $? -ne 0 ]; then
		msgbox "Something went wrong during installation."
		return 0
	fi
	# TODO make own .deb packages for this?
	wget https://github.com/afaqurk/linux-dash/archive/master.zip -O /var/www/linux-dash.zip
	cd /var/www
	# TODO check if every step worked?
	unzip linux-dash.zip
	mv linux-dash-master html/linux-dash
	rm -f linux-dash.zip
	msgbox "Linux Dash was installed.
You can access Linux Dash by pointing your browser to http://`hostname`/linux-dash/"
	# configure? TODO add .htaccess or something?
#	configure_linux_dash
}

configure_linux_dash()
{
	return 0
}

start_server()
{
	service apache2 restart
	if [ $? -ne 0 ]; then
		msgbox "Can't start apache2 server, please check logs."
		return 0
	fi
	return 0
}

intro
