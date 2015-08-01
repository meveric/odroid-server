#!/bin/bash

intro()
{
	msgbox "Here you can change the password for a any user on your system."
        CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to change a user password now?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
                ask_for_user
        fi
}

ask_for_user()
{
	OPTIONS=""
	USERS=""
	OIFS="$IFS"
	IFS="$(printf '\n\t')"
	for userid in `getent passwd`
	do
		if [ `echo $userid | cut -d ":" -f3` -ge 1000 ] && [ `echo $userid | cut -d ":" -f3` -le 2000 ]; then
			USERS="`echo $userid | cut -d ":" -f1` $USERS"
		fi
	done
	IFS="$OIFS"
	i=1
	for USER in $USERS
	do
		OPTIONS="$USER $i
$OPTIONS"
		i=$(($i+1))
	done
	OPTIONS="root $i
$OPTIONS"
	USER=""
	USER=$(whiptail --backtitle "$TITLE" --menu "Select User" 0 0 1 \
		$OPTIONS \
		3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		msgbox "A secure password should have 10 or more characters consisting of small and big letters and numbers and/or special characters"
		PASSWORD=$(whiptail --backtitle "$TITLE" --passwordbox "Please enter new password for user $USER:" 7 50  3>&1 1>&2 2>&3)
	fi
	if [ $? -eq 1 ]; then
		return
	else
		if [ "x$PASSWORD" == "x" ]; then
			msgbox "Empty password is not allowed at the moment"
			return
		fi
	fi
	echo -e "$PASSWORD\n$PASSWORD" | passwd $USER 
}
intro
