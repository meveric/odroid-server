#!/bin/bash

intro()
{
	msgbox "Here you can change the userid of a existing user to a different userid (e.g. rename the default user).
This will only work if the user is not logged in at the moment!!!"
        CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to rename a user now?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
                ask_for_user
        fi
}

ask_for_user()
{
	OLDNAME=$(whiptail --backtitle "$TITLE" --inputbox "Current user name (e.g. linaro):" 0 20 "linaro" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		return
	else
		if [ "x$OLDNAME" == "xroot" ]; then
			msgbox "root can not be renamed!"
			ask_for_user
			return
		elif [ "x$OLDNAME" == "x" ]; then
			msgbox "no name entered leaving..."
			return
		fi
	fi
	# check if user is still logged in
	for users in `ps aux | awk '{ print $1 }'`
	do
		if [ "x$users" == "x$OLDNAME" ]; then
			msgbox "User $OLDNAME is still logged on.. Renaming does not work if the user is still logged in or has services running under the same name"
			return
		fi
	done
	# check if user exists in /home
	if [ ! -d /home/$OLDNAME ]; then
		msgbox "User $OLDNAME seems not to exist, or the user has no home folder..."
		return
	fi
	msgbox "New user names should only include small letters and numbers starting with a number is not allowed."
	NEWNAME=$(whiptail --backtitle "$TITLE" --inputbox "new user name (e.g. odroid):" 0 20 "" --cancel-button "Exit" --ok-button "Select" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ]; then
		return
	else
		if [ "x$OLDNAME" == "x$NEWNAME" ]; then
			msgbox "nothing to do..."
			return
		else
			# TODO validate input
			# make sure everything is small letters
			NEWNAME=`echo $NEWNAME | tr [:upper:] [:lower:]`
			CC=$(whiptail --backtitle "$TITLE" --yesno "Are you sure you want to rename $OLDNAME to $NEWNAME?" 0 0 3>&1 1>&2 2>&3)
			if [ $? -eq 0 ]; then
				usermod -l $NEWNAME $OLDNAME
				groupmod -n $NEWNAME $OLDNAME
				mv /home/$OLDNAME /home/$NEWNAME/
				usermod -d /home/$NEWNAME $NEWNAME
			else
				return
			fi
		fi
	fi
}
intro
