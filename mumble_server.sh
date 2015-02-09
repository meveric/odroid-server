#!/bin/bash
intro()
{
	msgbox "With a Mumble Server your server can act as a Low latency VoIP server allowing you to make calls and talk over microphone with multiple people at once."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a Mumble Server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		install_jabber
	fi
}

install_jabber()
{
	get_updates
	apt-get install -y mumble-server
	if [ $? -ne 0 ]; then
		msgbox "Something went wrong during installation."
		return 0
	fi
	# configure?
	configure_mumble
}

configure_mumble()
{
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to use a password for your server?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
		PASSWORD=$(whiptail --backtitle "$TITLE" --title "Select password for your mumble server" --passwordbox "PASSWORD" 0 20 "" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	        # if Exit then go back to menu
        	if [ $? -eq 1 ]; then
                	return 0
	        fi
		if [ "x$PASSWORD" == "x" ]; then
			msgbox "No password entered, skipping password setting"
			return 0
		fi
		sed -i "s/^serverpassword=.*/serverpassword=$PASSWORD/" /etc/mumble-server.ini
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to change default port (64738) for your server?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		PORT=$(whiptail --backtitle "$TITLE" --title "Select connection-port for your mumble server" --inputbox "Mumble Server Port" 0 20 "" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ]; then
			return 0
		fi
		if [ "x$PORT" == "x" ]; then
			msgbox "No port entered, skipping port setting"
			return 0
		fi
		sed -i "s/^port=.*/port=$PORT/" /etc/mumble-server.ini
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to change the maximal audio quality of the server?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		CC=$(whiptail --backtitle "$TITLE" --menu "Main Menu" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
			"1" " 64kbit (low quality)" \
			"2" " 72kbit (standard quality)" \
			"3" "128kbit (high quality)" \
		3>&1 1>&2 2>&3)
		if [ $? -eq 1 ]; then
			msgbox "keeping current settings"
		else
			case "$CC" in
				"1") sed -i "s/^bandwidth=.*/bandwidth=64000/" /etc/mumble-server.ini ;;
				"2") sed -i "s/^bandwidth=.*/bandwidth=72000/" /etc/mumble-server.ini ;;
				"3") sed -i "s/^bandwidth=.*/bandwidth=128000/" /etc/mumble-server.ini ;;
				*) msgbox "Error 008. Please report on the forums" && exit 0 ;;
			esac
		fi
	fi
	# configure superuser and priority
	dpkg-reconfigure mumble-server
	start_server
}

start_server()
{
	service mumble-server restart
	if [ $? -ne 0 ]; then
		msgbox "Can't start mumble server, please check logs."
		return 0
	else
		msgbox "Mumble server started"
		return 0
	fi
}

intro
