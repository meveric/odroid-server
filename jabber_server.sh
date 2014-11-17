#!/bin/bash
intro()
{
	msgbox "With a Jabber (XMPP) Server your server can act as a Instant Messenging (IM) server allowing you to type message, talk over microphone and/or webcam or share files."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure a Jabber (XMPP) Server now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		install_jabber
	fi
}

install_jabber()
{
	if [ `which java | wc -l` -lt 1 ]; then
		get_updates
		apt-get install -y default-jre-headless
	fi
	# get openfire (right now version 3.9.3)
	if [ -f openfire.deb ]; then
		rm -f openfire.deb
	fi
	wget -O openfire.deb http://www.igniterealtime.org/downloadServlet?filename=openfire/openfire_3.9.3_all.deb
	# install openfire
	dpkg -i openfire.deb
	if [ $? -eq 0 ]; then
		rm -f openfire.deb
	fi
	# configure?
	configure_jabber
}

configure_jabber()
{
	msgbox "Open http://<IP-OF-JABBER-SERVER>:9090 in your browser to configure Openfire"
}

intro
