#!/bin/bash
# 2022 - Fernando Della Torre
source functions/colors.sh
source functions/IPprefix_by_netmask.sh
source functions/detect_os.sh
clear
detect_os
#os="debian-11"
# Quit if not running suported O.S.
if ! [[ $os == "debian-11" || $os == "ubuntu-20.04" ]]; then
	echo -e "${LRED}This script does not support your O.S.${NC}"
	echo -e "${LWHITE}You are running ${YELLOW}$os${NC}."
	echo ""
	exit 0
fi
#nic=`sudo lshw -class network | grep "logical name\|nome lógico" | cut -d ":" -f 2 | head -1 | xargs`
nics=($(ls -l /sys/class/net/ | grep -v virtual | cut -d " " -f9 | grep .))
clear
echo -e "\e[1;97;42m                                                                              ${NC}"
echo -e "\e[1;97;42m                        NETWORK INTERFACE CONFIGURATION                       ${NC}"
echo -e "\e[1;97;42m                                                                   bs4it@2022 ${NC}"
echo " "
echo -e "${YELLOW}ATTENTION!${NC}"
echo ""
echo -e "If you are using any special network configuration like vlan tagging, network"
echo -e "teaming or bridging, please ${LRED}DON'T${NC} go ahead."
echo -e "You must perform the configurations manually."
echo ""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Do you really want to go ahead? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			echo "OK!"
			sleep 1
			;;
		n|N)
			echo "Quitting, bye!"
			exit 0
			;;
  	esac
done
clear
echo -e "\e[1;97;42m                                                                              ${NC}"
echo -e "\e[1;97;42m                        NETWORK INTERFACE CONFIGURATION                       ${NC}"
echo -e "\e[1;97;42m                                                                   bs4it@2022 ${NC}"
echo " "
echo -e "${YELLOW}NIC Selection:${NC}"
echo ""
count=0
for i in "${nics[@]}"
do
	((++count))
	echo -n $count "- "
	echo "$i"
done
echo ""
nic_selection=0
while [[ $nic_selection = "" || $nic_selection -le 0  || $nic_selection -gt $count ]]
do
	echo -n -e "Select NIC by number:"
	read nic_selection
	if [[ $nic_selection -le 0  || $nic_selection -gt $count ]]; then
		echo "Selection out of range."
	fi
done
nic=${nics[($nic_selection-1)]}
echo ""
echo -e "Selected NIC ${YELLOW}$nic${NC}"
sleep 1
clear
echo -e "\e[1;97;42m                                                                              ${NC}"
echo -e "\e[1;97;42m                        NETWORK INTERFACE CONFIGURATION                       ${NC}"
echo -e "\e[1;97;42m                                                                   bs4it@2022 ${NC}"
echo " "
echo -e "${YELLOW}Setting up interface: $nic${NC}"
echo ""
echo "The values you type here will be used without any validation, so be careful."
echo -e "The settings will to applied to the NIC you selected: ${YELLOW}$nic${NC}"
echo -e "${WHITE}!!!DOUBLE CHECK BEFORE HITTING ENTER!!!${NC}"
echo ""
echo -e "${WHITE}You can cancel at any time by pressing CTRL+C.${NC}"
echo ""
echo -n -e "${WHITE}Hostname (no suffix): ${NC}"
read newhostname
echo -n -e "${WHITE}IP Address: ${NC}"
read ip
echo -n -e "${WHITE}Network Mask: ${NC}"
read nmask
echo -n -e "${WHITE}Gateway: ${NC}"
read gw
echo -n -e "${WHITE}DNS Server 1: ${NC}"
read dns1
echo -n -e "${WHITE}DNS Server 2: ${NC}"
read dns2
echo -n -e "${WHITE}DNS Suffix: ${NC}"
read dnssuffix
echo ""
prefix=$(IPprefix_by_netmask $nmask)
if [ -z $dns1 ]; then
	dns1="1.1.1.1"
fi
if [ -z $dns2 ]; then
	dns2="8.8.8.8"
fi
if [ -z $dnssuffix ]; then
	dnssuffix="network.intra"
fi
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "${WHITE}Are you sure you want to apply the configurations above? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			echo "Writting configuration..."
			sleep 1
			;;
		n|N)
			echo "Quitting, bye!"
			exit 0
			;;
  	esac
done
# get current hostname
hostname=`hostname -s`
# add new hostname to /etc/hosts
sudo sed -i "/$hostname/c\127.0.0.1\t$newhostname.$dnssuffix\t$newhostname\n127.0.0.1\t$hostname.$dnssuffix\t$hostname" /etc/hosts > /dev/null
# set new hostname
sudo hostnamectl set-hostname $newhostname 

if [ $os == "debian-11" ]; then
	# Backups original config
	mv /etc/network/interfaces /etc/network/interfaces.$(date +%Y-%m-%d_%Hh%Mm%Ss)
	# creates a new config containing only loopback and sourcing interfaces.d folder
	sudo bash -c "cat > /etc/network/interfaces" <<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
EOF

	# creates a config file for the interface
	if [ $gw ]; then
		gw_line="gateway $gw"
	else
		gw_line=""
	fi
	sudo bash -c "cat > /etc/network/interfaces.d/$nic" <<EOF
# This file describes the network interface $nic
auto $nic
iface $nic inet static
  address $ip/$prefix
  $gw_line
  dns-domain $dnssuffix
  dns-nameservers $dns1 $dns2
EOF
	# creates resolv.conf file
	sudo bash -c "cat > /etc/resolv.conf" <<EOF
domain $dnssuffix
search $dnssuffix
nameserver $dns1
nameserver $dns2
EOF
echo "Applying Network Configuration..."
sudo systemctl restart networking.service
elif [ $os == "ubuntu-20.04" ]; then
	sudo rm -f /etc/netplan/*.yaml
	sudo cat > /etc/netplan/01-$nic.yaml <<EOF
# This is the network config written by 'BS4IT lnxrepo script'
network:
  ethernets:
    $nic:
      addresses:
      - $ip/$prefix
      gateway4: $gw
      nameservers:
        addresses:
        - $dns1
        - $dns2
        search:
        - $dnssuffix
  version: 2
EOF
	echo "Applying Network Configuration..."
	sudo netplan apply
fi
# removing old hostname from /etc/hosts
sudo sed -i "/$hostname/d" /etc/hosts > /dev/null
echo -e "${YELLOW}Done!${NC}"
sleep 2
exit 0
