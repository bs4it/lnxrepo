#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/functions/colors.sh
source $(dirname "$0")/functions/IPprefix_by_netmask.sh
source $(dirname "$0")/functions/detect_os.sh
source $(dirname "$0")/functions/build_banner.sh
trap '' 2
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

# while [[ $nic_selection = "" || $nic_selection -le 0  || $nic_selection -gt $count ]]
# do
# 	echo -n -e "Select NIC by number: "
# 	read nic_selection
# 	if [[ $nic_selection -le 0  || $nic_selection -gt $count ]]; then
# 		echo "Selection out of range."
# 	fi
# done



while [[ $selection = "" || $selection -le 0  || $selection -gt $count ]]
#while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	clear
	build_banner "BS4IT - Linux Hardened Repository Setup" "bs4it@2022"
	echo " "
	echo -e "${YELLOW}Linux Hardened Repository Setup${NC}" 
	echo -e "${CYAN}$os detected.${NC}"
	echo " "
	echo -e "This set of tools helps you to setup and maintain a Linux Hardened Repository."
	echo -e "Select to run the Deploy Wizard or the desired standalone feature."
	echo ""
	echo -e ""
	echo -e " ${YELLOW}0${NC} - Deploy Wizard"
	echo -e " ${YELLOW}1${NC} - Set Network Interface"
	echo -e " ${YELLOW}2${NC} - Update and Install Packages + OS Customizations"
	echo -e " ${YELLOW}3${NC} - Harden SSH, Firewall + Install Log Collection Script"
	echo -e " ${YELLOW}4${NC} - Create Users + Get Credentials"
	echo -e " ${YELLOW}5${NC} - Setup iSCSI"
	echo -e " ${YELLOW}6${NC} - Setup Disk, LVM, Filesystem and Mount Point + Permissions"
	echo -e " ${YELLOW}7${NC} - Add to Veeam backup & Replication Console"
	echo -e " ${YELLOW}8${NC} - Quit"
	echo ""
	echo -n -e "Your selection ${YELLOW}(0)${NC}: "
	read selection
	 	if [[ $selection -lt 0  || $selection -gt 8 ]]; then
 			echo "Selection out of range."
			sleep 1
 		fi
	case $selection in
		0)
			(trap 2; bash $(dirname "$0")/_wizard.sh)
			sleep 0.3
			;;
		1)
			(trap 2; bash $(dirname "$0")/set_net.sh)
			sleep 0.3
			;;
		2)
			(trap 2; bash $(dirname "$0")/set_updates+install.sh)
			sleep 0.3
			;;
		3)
			(trap 2; bash $(dirname "$0")/set_harden.sh)
			sleep 0.3
			;;
		4)
			(trap 2; bash $(dirname "$0")/set_users.sh)
			sleep 0.3
			;;
		5)
			(trap 2; bash $(dirname "$0")/set_iscsi.sh)
			sleep 0.3
			;;
		6)
			(trap 2; bash $(dirname "$0")/set_disk.sh)
			sleep 0.3
			;;
		7)
			(bash $(dirname "$0")/add_to_console.sh)
			sleep 0.3
			;;
		8)
			echo "Quitting, bye!"
			trap 2
			exit 0
			;;
		
  	esac
done
