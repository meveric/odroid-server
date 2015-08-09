#!/bin/bash
intro()
{
	msgbox "The minidlna daemon serves media files (music, pictures, and video)
 to clients on your network."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a minidlna Server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		# do some crazy stuff
		install_dlna
		return 0	
	fi
}

install_dlna()
{
	get_updates
	wget http://launchpadlibrarian.net/175547819/minidlna_1.1.2%2Bdfsg-1%7Eubuntu14.04.1_armhf.deb
	dpkg -i "minidlna_1.1.2+dfsg-1~ubuntu14.04.1_armhf.deb"
	apt-get install -fy
	if [ ! $? -eq 0 ]; then
		msgbox "Installation failed, please ask for help in forums"
		return 0
	fi
	rm -f "minidlna_1.1.2+dfsg-1~ubuntu14.04.1_armhf.deb"
	configure_dlna
}

configure_dlna()
{
	AUDIO=$(whiptail --backtitle "$TITLE" --title "Music folder" --inputbox "Enter the path of your music library (e.g. /srv/music):" 0 20 "/srv/music" 3>&1 1>&2 2>&3)
	VIDEO=$(whiptail --backtitle "$TITLE" --title "Movie folder" --inputbox "Enter the path of your movie library (e.g. /srv/movies):" 0 20 "/srv/movies" 3>&1 1>&2 2>&3)
	PICTURES=$(whiptail --backtitle "$TITLE" --title "Picture folder" --inputbox "Enter the path of your picture library (e.g. /srv/pictures):" 0 20 "/srv/pictures" 3>&1 1>&2 2>&3)
	if [ "x$AUDIO" != "x" ]; then
		sed -i "s/^media_dir=\/var\/lib\/minidlna/# media_dir=\/var\/lib\/minidlna/" /etc/minidlna.conf
		echo "media_dir=A,$AUDIO" >> /etc/minidlna.conf
	fi
	if [ "x$VIDEO" != "x" ]; then
                sed -i "s/^media_dir=\/var\/lib\/minidlna/# media_dir=\/var\/lib\/minidlna/" /etc/minidlna.conf
                echo "media_dir=V,$VIDEO" >> /etc/minidlna.conf
        fi
	if [ "x$PICTURES" != "x" ]; then
                sed -i "s/^media_dir=\/var\/lib\/minidlna/# media_dir=\/var\/lib\/minidlna/" /etc/minidlna.conf
                echo "media_dir=P,$PICTURES" >> /etc/minidlna.conf
        fi
	# configure inotify
	if [ `grep "^fs.inotify.max_user_watches=65536" /etc/sysctl.conf | wc -l` -lt 1 ]; then
		echo "fs.inotify.max_user_watches=65536" >> /etc/sysctl.conf
		sysctl -p
	fi
	fi
	# setup inotify in minidlna
	if [ `grep "^inotify=yes" /etc/minidlna.conf | wc -l` -lt 1 ]; then
		echo "inotify=yes" >> /etc/minidlna.conf
	fi
	if [ `grep "^notify_interval=300" /etc/minidlna.conf | wc -l` -lt 1 ]; then
		echo "notify_interval=300" >> /etc/minidlna.conf
	fi
			
	restart_server
}

restart_server()
{
	CC=$(whiptail --backtitle "$TITLE" --yesno "Minidlna Server configuration changed, do you want to restart server now?" 0 0 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
                service minidlna restart
        fi
}

intro
