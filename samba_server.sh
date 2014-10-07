#!/bin/bash
intro()
{
	msgbox "With a Samba Server you can share files and folder in your network similar as under windows."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a Samba Server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		# do some crazy stuff
		return 0	
	fi
}
