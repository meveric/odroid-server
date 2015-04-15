#!/bin/bash
intro()
{
        msgbox "With BackupPC you can backup your Linux systems and do a recovery in case something breaks down or a file gets deleted accidentally. 
The software supports remote backup of differnt systems and different backup strategies."
        CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure BackupPC now?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
                install_backuppc
        fi
}
install_backuppc()
{
	get_updates
	apt install -y apache2-utils backuppc sshpass
	if [ $? -ne 0 ]; then
		msgbox "Something went wrong during installation of BackupPC."
		return
	else
		# restarting web server due to some new modules
		service apache2 restart
		msgbox "BackupPC installed sucessfully."
	fi
	configure_backuppc
}

configure_backuppc()
{
	# TODO create own password for WebInterface?

	# create template
	echo "# Do not do any automatic backups on this machine
\$Conf{BackupsDisable} = 0;

\$Conf{XferMethod} = 'rsync';

\$Conf{BackupFilesExclude} = [
                '/proc',
                '/sys',
		'/dev',
                '/tmp',
                '/mnt',
];
" > /etc/backuppc/template

	# create ssh key for user backuppc
	if [ ! -d /var/lib/backuppc/.ssh ]; then
		mkdir /var/lib/backuppc/.ssh
		chown backuppc:backuppc /var/lib/backuppc/.ssh
	fi
	if [ ! -f /var/lib/backuppc/.ssh/id_rsa ]; then
		ssh-keygen -t rsa -b 4096 -q -f /var/lib/backuppc/.ssh/id_rsa -N ''
		chown -R backuppc:backuppc /var/lib/backuppc/.ssh
	fi
	msgbox "Configuration Completed, you can now use BackupPC from the WebInterface."
	return
}

intro
