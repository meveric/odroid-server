#!/bin/bash
intro()
{
	msgbox "With OwnCloud you can create your own personal Cloud Server similar to Dropbox to store and organize your files and sync them between devices, all while having complete control over your files and not giving your files to a third party."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a OwnCloud Server now?" 0 0 3>&1 1>&2 2>&3)
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
	configure_owncloud
	start_server
}

configure_owncloud()
{
	CC=$(whiptail --backtitle "$TITLE" --yesno "OwnCloud uses a database to store information about users and calendars, contacts, etc.
You can either use the build in SQLite database, or a MySQL/MariaDB database, or a PostgreSQL database. For easy usage a MySQL database was already installed.

Do you want to setup a mysql database and user for OwnCloud server?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		return 0
	fi
	# TODO: setup mysql server
	DATABASE_NAME=$(whiptail --backtitle "$TITLE" --title "Database Name" --inputbox "Please define a name for the OwnCloud mysql database:" 0 20 "owncloud" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$DATABASE_NAME" == "x" ]; then
		msgbox "Skipping MySQL configuration"
		return 0
	fi
	DATABASE_USER=$(whiptail --backtitle "$TITLE" --title "Database User" --inputbox "Please define a name for the database user:" 0 20 "owncloud" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$DATABASE_USER" == "x" ]; then
		msgbox "Skipping MySQL configuration"
		return 0
	fi
	USER_PW=$(whiptail --backtitle "$TITLE" --title "User Password" --passwordbox "Please select a password for your MySQL user" 0 20 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$USER_PW" == "x" ]; then
		msgbox "Skipping MySQL configuration"
		return 0
	fi
	echo "CREATE DATABASE $DATABASE_NAME;" | mysql --defaults-file=/etc/mysql/debian.cnf
	if [ $? -ne 0 ]; then
		msgbox "Something went wrong while creating database \"$DATABASE_NAME\" please check output and fix issues, or report to forums"
		exit 100
	fi
	echo "GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO '$DATABASE_USER'@'localhost' IDENTIFIED BY '$USER_PW';" | mysql --defaults-file=/etc/mysql/debian.cnf
	if [ $? -ne 0 ]; then
		msgbox "Something went wrong while creating database user \"$DATABASE_USER\" please check output and fix issues, or report to forums"
		exit 101
	fi
	return 0
}

start_server()
{
	service apache2 restart
	if [ $? -ne 0 ]; then
		msgbox "Can't start apache2 server, please check logs."
		return 0
	else
		msgbox "OwnCloud installed. Direct your browser to http://`hostname`/owncloud to finish setup
If you setup a MySQL Database make sure to click on \"Storage & database\" to configure your database."
	fi
	return 0
}

intro
