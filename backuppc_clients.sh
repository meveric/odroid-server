#!/bin/bash
menu()
{
	CC=$(whiptail --backtitle "$TITLE" --menu " Menu" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
                " 1" "Add a system for backups" \
                " 2" "Disable a system from backups" \
                " 3" "Remove a system from backups" \
                " 4" "Re-enable system for backups" \
                3>&1 1>&2 2>&3)
        if [ $? -eq 1 ]; then
                return
        else
                case "$CC" in
                " 1") add_system;;
                " 2") disable_system;;
                " 3") remove_system;;
                " 4") enable_system;;
                *) msgbox "Error 009. Please report on the forums" && exit 0 ;;
                esac || msgbox "I don't know how you got here! >> $CC <<  Report on the forums"
        fi
}

add_system()
{
	PCNAME=$(whiptail --backtitle "$TITLE" --title "Add PC for backup" --inputbox "Enter the DNS name or IP address of the system you want to backup:" 0 40 "" 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		if [ "x$PCNAME" != "x" ]; then
			PCNAME=`echo $PCNAME | tr [:upper:] [:lower:]`
			if [ `cat /etc/backuppc/hosts | grep $PCNAME | wc -l` -lt 1 ]; then
				cp /etc/backuppc/template /etc/backuppc/${PCNAME}.pl
				echo "$PCNAME	0	backuppc" >> /etc/backuppc/hosts
				ROOTPW=$(whiptail --backtitle "$TITLE" --title "Security Credentials" --passwordbox "root password of the new system (keep empty if root has no password and follow the instructions):" 0 20 "" 3>&1 1>&2 2>&3)
				if [ $? -eq 0 ]; then
					if [ "x$ROOTPW" != "x" ]; then
						ssh-keyscan -H $PCNAME >> /root/.ssh/known_hosts
						ssh-keyscan -H $PCNAME >> /var/lib/backuppc/.ssh/known_hosts
						sshpass -p "$ROOTPW" ssh-copy-id -i /var/lib/backuppc/.ssh/id_rsa.pub root@$PCNAME
						if [ $? -ne 0 ]; then
							msgbox "Something went wrong please follow the information given next:"
							info_rsync
							return
						fi
					else
						msgbox "Empty password given. Please follow the directions shown next."
						info_rsync
						return
					fi
				else
					info_rsync
					return
				fi
			else
				msgbox "host already exists."
				menu
				return
			fi
		else
			msgbox "No name entered, skipping"
			menu
			return
		fi
	fi
}

info_rsync()
{
	msgbox "!!!PLEASE READ CAREFULLY!!!
BackupPC uses rsync and ssh to backup data from the hosts you defined.
Therefore requires to logon as root on the destination system.

Manual steps if user root DOES have a password:
1. logon as backuppc (or as root type su - backuppc)
2. use the following command to tranfer the ssh key for backuppc:
  ssh-copy-id -i /var/lib/backuppc/.ssh/id_rsa.pub root@$PCNAME

Manual steps if user root does NOT have a password (e.g. Ubuntu Servers):
1. logon as backuppc (or as root type su - backuppc)
2. use the following command to copy the public key to the system:
  scp /var/lib/backuppc/.ssh/id_rsa.pub <USER>@$PCNAME:authorized_keys
where <USER> is the name of the user you have login credentials for.
3. Log on the remote host using the following command:
  ssh <USER>@$PCNAME
4. On the remote system turn yourself to root using \"sudo -s\" as a command
5. Create /root/.ssh/ if not exist with:
  mkdir -p /root/.ssh
6. Add the content of authorized_keys to /root/.ssh/authorized_keys:
  cat authorized_keys >> /root/.ssh/authorized_keys"
}

# TODO only show active systems
disable_system()
{
	OPTIONS=""
	FILE=""
	NUM_FILES=`find /etc/backuppc -type f | grep ".pl$" | grep -v "config.pl" | wc -l`
	i=0
	for files in `find /etc/backuppc -type f | grep ".pl$" | grep -v "config.pl"`
	do
		PC=`echo $files | sed "s/\.pl//" | sed "s/\/etc\/backuppc\///"`
		OPTIONS="$PC $(($NUM_FILES-$i))
$OPTIONS"
		i=$(($i+1))
	done
	DISABLE=$(whiptail --backtitle "$TITLE" --menu "Select the system where you want to disable backup:" 0 0 1 \
		$OPTIONS \
		3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		FILE=/etc/backuppc/${DISABLE}.pl
		if [ `grep "\$Conf{BackupsDisable} = 1;" $FILE | wc -l` -ge 1 ]; then
			msgbox "$DISABLE is already disabled from automatic backup."
		else
			sed -i "s/\$Conf{BackupsDisable} = 0;/\$Conf{BackupsDisable} = 1;/" $FILE
		fi
	fi
	menu
	return
}

remove_system()
{
	OPTIONS=""
	FILE=""
	NUM_FILES=`find /etc/backuppc -type f | grep ".pl$" | grep -v "config.pl" | wc -l`
	i=0
	for files in `find /etc/backuppc -type f | grep ".pl$" | grep -v "config.pl"`
	do
		PC=`echo $files | sed "s/\.pl//" | sed "s/\/etc\/backuppc\///"`
		OPTIONS="$PC $(($NUM_FILES-$i))
$OPTIONS"
		i=$(($i+1))
	done
	REMOVE=$(whiptail --backtitle "$TITLE" --menu "Select the system where you want to disable backup:" 0 0 1 \
		$OPTIONS \
		3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		FILE=/etc/backuppc/${DISABLE}.pl
		rm -f "$FILE"
		sed -i "`grep -n $REMOVE /etc/backuppc/hosts | cut -d ":" -f1`d" /etc/backuppc/hosts
		if [ $? -eq 0 ]; then
			# TODO ask if files should be removed?
			msgbox "$REMOVE was successfully removed from backup list. 
Please Note: All backuped files are still present and were not deleted"
		fi
	fi
	menu
	return
}

#TODO only show inactive systems
enable_system()
{
	OPTIONS=""
	FILE=""
	NUM_FILES=`find /etc/backuppc -type f | grep ".pl$" | grep -v "config.pl" | wc -l`
        i=0
	for files in `find /etc/backuppc -type f | grep ".pl$" | grep -v "config.pl"`
	do
		PC=`echo $files | sed "s/\.pl//" | sed "s/\/etc\/backuppc\///"`
		OPTIONS="$PC $(($NUM_FILES-$i))
$OPTIONS"
		i=$(($i+1))
	done
	ENABLE=$(whiptail --backtitle "$TITLE" --menu "Select the system where you want to enable backup:" 0 0 1 \
		$OPTIONS \
		3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		FILE=/etc/backuppc/${ENABLE}.pl
		if [ `grep "\$Conf{BackupsDisable} = 0;" $FILE | wc -l` -ge 1 ]; then
			msgbox "$ENSABLE is already enabled from automatic backup."
		else
			sed -i "s/\$Conf{BackupsDisable} = 1;/\$Conf{BackupsDisable} = 0;/" $FILE
		fi
	fi
	menu
	return
}

menu
