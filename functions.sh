#!/bin/bash
# helper functions
msgbox() {
        # $1 is the msg
        whiptail --backtitle "ODROID Server Menu" --msgbox "$1" 0 0 0
}

