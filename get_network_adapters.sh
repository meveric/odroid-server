#!/bin/bash

num_devices=`ip addr show | grep eth.: | wc -l`
if [ $num_devices -gt 1 ]; then
	i=0
	menu=""
	while [ $i -lt $num_devices ]
	do
		if [ "x$menu" == "x" ]; then
			menu="$i eth$i"
		else
			menu="$menu $i eth$i"
		fi
		i=$(($i+1))
	done
	CC=$(whiptail --backtitle "$TITLE" --menu "Select ethernet device" 0 0 1 --cancel-button "Exit" --ok-button "Select" \
	$menu \
	3>&1 1>&2 2>&3)
	result=$?
	if [ $result -eq 0 ]; then
		echo "eth$CC"
	fi
else
	echo "eth0"
fi
