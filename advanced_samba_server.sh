#!/bin/bash
intro()
{
	msgbox "Here you can configure and reconfigure your samba server add/remove users and shares or change passwords."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to continue?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		ask_for_task
	fi
}

ask_for_task()
{
	CC=$(whiptail --backtitle "$TITLE" --menu "What do you want to change?" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
		"1"	"Add Samba user" \
		"2"	"Remove Samba user" \
		"3"	"Change Samba user password" \
		"4"	"Add shared folder" \
		"5"	"Remove shared folder" \
	3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		# TODO add modify share?
		case "$CC" in
		"1") add_user ;;
		"2") remove_user ;;
		"3") change_pass ;;
		"4") add_share ;;
		"5") remove_share ;;
		*) msgbox "Error 010. Please report on the forums" && exit 0 ;;
		esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
	else
		return 0
	fi
}

add_user()
{
	USER=$(whiptail --backtitle "$TITLE" --title "Add User" --inputbox "Login of the new user (only small letters):" 0 20 "" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$USER" == "x" ]; then
		ask_for_task
		return
	else
		USER=`echo $USER | tr [:upper:] [:lower:]`
		for user in `pdbedit -L | cut -d ":" -f1`
		do
			if [ "x$USER" == "x$user" ]; then
				msgbox "User already exists."
				ask_for_task
				return
			fi
		done
		PASSWORD=$(whiptail --backtitle "$TITLE" --title "Add User" --passwordbox "Password for new $USER:" 7 50 "" 3>&1 1>&2 2>&3)
		if [ $? -eq 1 ] || [ "x$PASSWORD" == "x" ]; then
			msgbox "No password is not supported at the moment."
			ask_for_task
			return
		else
			# create system user can fail if user already exists
			useradd $USER -p $PASSWORD
			# create samba user should not fail
			echo -e "$PASSWORD\n$PASSWORD" | smbpasswd -a $USER
			if [ $? -ne 0 ]; then
				msgbox "Creation of samba user $USER failed, check log."
				exit 1
			fi
		fi
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "User $USER created. Do you want to add another user?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		add_user
	else
		ask_for_task
	fi
}

remove_user()
{
	msgbox "Only samba users will be removed the user account will not be removed.
Which user do you want to remove?"
	select_user
	if [ "x$USER" == "xroot" ]; then
		return
	fi
	smbpasswd -x $USER
	CC=$(whiptail --backtitle "$TITLE" --yesno "User $USER removed. Do you want to remove another user?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		remove_user
	else
		ask_for_task
	fi
}

change_pass()
{
	msgbox "This section will reset your samba users password.
For which user do you want to change the password?"
	select_user
	if [ "x$USER" == "xroot" ]; then
		msgbox "User root should not be touched here."
                return
        fi
	PASSWORD=$(whiptail --backtitle "$TITLE" --title "Change Password" --passwordbox "New Password for $USER:" 7 50 "" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$PASSWORD" == "x" ]; then
		msgbox "No password is not supported at the moment."
		ask_for_task
		return
	else
		echo -e "$PASSWORD\n$PASSWORD" | smbpasswd $USER
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "User $USER created. Do you want to add another user?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		change_pass
	else
		ask_for_task
	fi
}		

add_share()
{
	SHARE=""
	DESCRIPTION=""
	LOCATION=""
	SHARE_PARM=""
	SHARE=$(whiptail --backtitle "$TITLE" --title "Add Shared Folder" --inputbox "Name of new share:" 0 20 "" 3>&1 1>&2 2>&3)
	if [ $? -eq 1 ] || [ "x$SHARE" == "x" ]; then
		ask_for_task
		return
	else
		SHARE=`echo $SHARE | tr [:upper:] [:lower:]`
		# check if share already exists
		if [ `grep "\[$SHARE\]" /etc/samba/smb.conf | wc -l` -ge 1 ]; then
			msgbox "Share \"$SHARE\" does already exist please choose a different name."
			add_share
			return
		else
			DESCRIPTION=$(whiptail --backtitle "$TITLE" --title "Add Shared Folder" --inputbox "Enter a description for the new share (can be blank):" 0 20 "" 3>&1 1>&2 2>&3)
			LOCATION=$(whiptail --backtitle "$TITLE" --title "Add Shared Folder" --inputbox "Enter the path of the new share (e.g. /srv/share/):" 0 20 "" 3>&1 1>&2 2>&3)
			if [ $? -eq 1 ] || [ "x$LOCATION" == "x" ]; then
				ask_for_task
				return
			else
				# check if folder exist
				if [ ! -d $LOCATION ]; then
					CC=$(whiptail --backtitle "$TITLE" --yesno "$LOCATION does not exist. Do you want to create the share anyway?" 0 0 3>&1 1>&2 2>&3)
					if [ $? -eq 1 ]; then
						ask_for_task
						return
					fi
				fi
				share_parameters
				SHARE_PARM="[$SHARE]
	path = $LOCATION"
				if [ "x$DESCRIPTION" != "x" ]; then
					SHARE_PARM="$SHARE_PARM
	comment = $DESCRIPTION"
				fi
				SHARE_PARM="$SHARE_PARM
	$BROWSEABLE
	$GUEST
	$WRITEABLE"
				if [ "x$WRITE_USER" != "x" ]; then
					SHARE_PARM="$SHARE_PARM
	$WRITE_USER"
				fi
				# write config
				echo "
$SHARE_PARM" >> /etc/samba/smb.conf
				restart_server
				CC=$(whiptail --backtitle "$TITLE" --yesno "Share \"$SHARE\" created. Do you want to create another?" 0 0 3>&1 1>&2 2>&3)
				if [ $? -eq 0 ]; then
					add_share
				else
					ask_for_task
					return
				fi
			fi
		fi
	fi
}

share_parameters()
{
	BROWSEABLE=""
	GUEST=""
	WRITEABLE=""
	WRITE_USER=""
	CC=$(whiptail --backtitle "$TITLE" --yesno "Should the share \"$SHARE\" be visible for all users?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		BROWSEABLE="browseable = yes"
	else
		BROWSEABLE="browseable = no"
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Should the share \"$SHARE\" be accessable for all guests (no login required)?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		GUEST="guest ok = yes"
	else
		GUEST="guest ok = no"
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Should the share \"$SHARE\" be writeable for all users (logged in users only)?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		WRITEABLE="writeable = yes"
	else
		WRITEABLE="writeable = no"
		CC=$(whiptail --backtitle "$TITLE" --yesno "Should the share \"$SHARE\" be writeable for a single users anyway?" 0 0 3>&1 1>&2 2>&3)
		if [ $? -eq 0 ]; then
			# TODO
			# aborts if no user is select - not nice
			# for now only allow one user
			select_user
			WRITE_USER="write list = $USER"
		fi
		
	fi
}

select_share()
{
	OPTIONS=""
	SHARE=""
	SHARES=""
	i=0
	NUM_SHARES="`cat /etc/samba/smb.conf | grep "\[" | grep -v global | grep -v printers | grep -v print | grep -v homes | sed "s/\[//" | sed "s/\]//" | wc -l`"
	if [ $NUM_SHARES -ge 1 ]; then
		for SHARES in `cat /etc/samba/smb.conf | grep "\[" | grep -v global | grep -v printers | grep -v print | grep -v homes | sed "s/\[//" | sed "s/\]//"`
		do
			OPTIONS="$SHARES $(($NUM_SHARES-$i))
$OPTIONS"
			i=$(($i+1))
		done
		SHARE=$(whiptail --backtitle "$TITLE" --menu "Select Samba share:" 0 0 1 \
			$OPTIONS \
			3>&1 1>&2 2>&3)
		if [ $? -eq 1 ]; then
			msgbox "Aborting..."
			ask_for_task
			return
		fi
	else
		msgbox "No samba shares on this server."
		ask_for_task
		return
	fi
}

remove_share()
{
	msgbox "Here you can remove unwanted Samba shares.
Please select the share you want to remove:"
	select_share
	if [ "x$SHARE" == "x" ]; then
		ask_for_task
		return
	fi
	LINE=`grep -n "\[$SHARE\]" /etc/samba/smb.conf | cut -d ":" -f1`
	# check if some other share is after that share
	if [ `grep -n -A10 "\[$SHARE\]" /etc/samba/smb.conf | grep "\[" | wc -l` -gt 1 ]; then
		LINE_END=$((`grep -n -A8 "\[$SHARE\]" /etc/samba/smb.conf | grep "\[" | tail -n1 | cut -d "-" -f1`-1))
		sed -i "$LINE,${LINE_END}d" /etc/samba/smb.conf
	else
		# this share is the last entry so delete until end of line
		sed -i "$LINE,$ d" /etc/samba/smb.conf
	fi
	CC=$(whiptail --backtitle "$TITLE" --yesno "Share \"$SHARE\" removed. Do you want to remove another?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		remove_share
		return
	else
		ask_for_task
	fi
}

select_user()
{
	OPTIONS=""
	USERS=""
	NUM_USERS=`pdbedit -L | cut -d ":" -f1 | wc -l`
	i=0
	if [ $NUM_USERS -ge 1 ]; then
		for USERS in `pdbedit -L | cut -d ":" -f1`
		do
			OPTIONS="$USERS $(($NUM_USERS-$i))
$OPTIONS"
			i=$(($i+1))
		done
		USER=$(whiptail --backtitle "$TITLE" --menu "Select Samba user" 0 0 1 \
			$OPTIONS \
			3>&1 1>&2 2>&3)
		if [ $? -eq 1 ]; then
			msgbox "Aborting..."
			ask_for_task
			return 0
		fi
	else
		msgbox "No samba user on this server."
		ask_for_task
		return
	fi
}

restart_server()
{
	CC=$(whiptail --backtitle "$TITLE" --yesno "Samba Server configuration changed, do you want to restart server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		service smbd restart
	fi
}

intro
