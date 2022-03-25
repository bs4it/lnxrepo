#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/functions/colors.sh
source $(dirname "$0")/functions/IPprefix_by_netmask.sh
source $(dirname "$0")/functions/detect_os.sh
source $(dirname "$0")/functions/build_banner.sh
clear
#detect_os
os="debian-11"
# Quit if not running suported O.S.
if ! [[ $os == "debian-11" || $os == "ubuntu-20.04" ]]; then
	echo -e "${LRED}This script does not support your O.S.${NC}"
	echo -e "${LWHITE}You are running ${YELLOW}$os${NC}."
	echo ""
	exit 0
fi

clear
build_banner "BS4IT - Linux Hardened Repository Setup" "bs4it@2022"
echo " "
echo -e "${YELLOW}WELCOME!${NC}" 
echo "$os detected."
echo " "
echo -e "The next steps will help you to setup a Linux Hardened Repository to store your Veeam Backup & Replication data."
echo ""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Do you want to go ahead? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			echo "OK!"
			sleep 0.3
			;;
		n|N)
			echo "Quitting, bye!"
			exit 0
			;;
  	esac
done
clear
build_banner "BS4IT - Linux Hardened Repository Setup" "bs4it@2022"
echo " "
echo -e "${YELLOW}Step 1 - Network Interface Configuration:${NC}"
echo " "
echo -e "Do you want to setup network interfaces now? "
echo -e "You may lose access to this server depending on your settings."
echo " "
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Start network wizard now? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
            bash ./set_net.sh
			sleep 0.6
            read -p "Press ENTER to continue."
			;;
		n|N)
			;;
  	esac
done

clear
build_banner "BS4IT - Linux Hardened Repository Setup" "bs4it@2022"
echo " "
echo -e "${YELLOW}Step 2 - Update system and install packages:${NC}"
echo " "
echo -e "Do you want to update the system and install the required packages? "
echo -e "You need to have your network working to proceed."
echo " "
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Apply latest updates and install packages now? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			sleep 0.3
            bash ./functions/update+install_$os.sh
            read -p "Press ENTER to continue."
			;;
		n|N)
			;;
  	esac
done

clear
build_banner "BS4IT - Linux Hardened Repository Setup" "bs4it@2022"
echo " "
echo -e "${YELLOW}Step 3 - Setup iSCSI Initiator:${NC}"
echo " "
echo -e "Do you want to change iSCSI configuration?"
echo -e "If you proceed you may disconnect all active iSCSI sessions."
echo " "
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Start iSCSI initiator wizard now? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			sleep 0.3
            bash ./set_iscsi.sh
			sleep 0.6
            read -p "Press ENTER to continue."
			;;
		n|N)
			;;
  	esac
done

clear
build_banner "BS4IT - Linux Hardened Repository Setup" "bs4it@2022"
echo " "
echo -e "${YELLOW}Step 4 - Preparing Disk and Filesystem:${NC}"
echo " "
echo -e "In this step your disk will be prepared on a LVM setup, formated as XFS and mounted accordingly"
echo " "
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Start disk setup wizard now? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			sleep 0.3
            bash ./set_disk.sh
			sleep 0.6
            read -p "Press ENTER to continue."
			;;
		n|N)
			;;
  	esac
done
