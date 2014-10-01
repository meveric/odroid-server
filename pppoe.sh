#!/bin/bash

intro()
{
	msgbox "PPPoE is used to establish a connection with your Internet Service Provider (ISP). Commonly used for DSL Modems."
	CC=$(whiptail --backtitle "$TITLE" --yesno "Do you want to install and configure PPPoE now?" 0 0 3>&1 1>&2 2>&3)
	if [ $? -eq 0 ]; then
		install_pppoe
	fi
}
install_pppoe()
{
        if [ `dpkg --list | grep pppoe | wc -l` -lt 1 ] || [ `dpkg --list | grep pppoe | grep rc | wc -l` -eq 1  ]; then
                apt-get install -y pppoe
                if [ ! $? -eq 0 ]; then
                        msgbox "Installation failed, please ask for help in forums"
                        return 0
                fi
        fi
        configure_pppoe
}

configure_pppoe()
{
	pppoeconf
	# make sure pppoe is running on eth0
	sed -i "s/^plugin rp-pppoe.so.*/plugin rp-pppoe.so eth0/" "/etc/ppp/peers/dsl-provider"
	# set DNS servers
	echo "nameserver 127.0.0.1\n nameserver 8.8.8.8"> /etc/ppp/resolv.conf
}

intro
