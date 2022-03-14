#!/bin/bash
# Variaveis
mountpointdefault="/backup"
vg_name_default="vg_backup"
lv_name_default="lv_backup"
source functions/colors.sh
clear
echo -e "\e[1;97;42m                                                                              ${NC}"
echo -e "\e[1;97;42m                              DISK CONFIGURATION                              ${NC}"
echo -e "\e[1;97;42m                                                                   bs4it@2022 ${NC}"
echo " "
echo -e "${YELLOW}ATTENTION!${NC}"
echo ""
echo -e "${WHITE}The disk you're going to choose will be completely cleared, used as LVM and${NC}"
echo -e "${WHITE}formated using XFS.${NC}"
echo -e "${YELLOW}ALL DATA ON THE DISK YOU'LL SELECT WILL BE ${LRED}PERMANENTELY LOST!${NC}"
echo ""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Do you really want to go ahead? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			;;
		n|N)
			echo "Quitting, bye!"
			exit 0
			;;
  	esac
done
clear
echo -e "\e[1;97;42m                                                                              ${NC}"
echo -e "\e[1;97;42m                              DISK CONFIGURATION                              ${NC}"
echo -e "\e[1;97;42m                                                                   bs4it@2022 ${NC}"
echo " "
echo -e "${WHITE}The following block devices are present:${NC}"
echo " "
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL
echo " "
echo -e "${WHITE}You must choose a device with no partition, volume, mountpoint or filesystem.${NC}"
read -p "Press ENTER to continue."
clear
echo -e "\e[1;97;42m                                                                              ${NC}"
echo -e "\e[1;97;42m                              DISK CONFIGURATION                              ${NC}"
echo -e "\e[1;97;42m                                                                   bs4it@2022 ${NC}"
echo " "
echo -e "${WHITE}The following SCSI devices are attached to this system:${NC}"
echo " "
lsblk -S
echo " "
while [[ -z "$blkdevice" ]]
do
	echo -n -e "${WHITE}Enter the device you want to use (e.g. sdb): ${NC}"
	read blkdevice
done
echo ""
echo -e "${LRED}ALL DATA ON $blkdevice WILL BE PERMANENTELY LOST!${NC}"
echo -e "${LRED}THIS PROCESS CANNOT BE UNDONE!${NC}"
echo -e "${LRED}YOU MUST BE SURE ${YELLOW}$blkdevice ${LRED}IS EMPTY OR NO IMPORTANT DATA IS ON IT.${NC}"
echo " "
echo -n -e "${WHITE}Enter the device name again to continue: ${NC}"
read confirmdevice
if [ $confirmdevice != $blkdevice ]; then
	echo -e "${YELLOW}The confirmation you entered is wrong, quitting.${NC}"
	exit 1
fi
clear
echo -e "\e[1;97;41m                                                                              ${NC}"
echo -e "\e[1;97;41m                              DISK CONFIGURATION                              ${NC}"
echo -e "\e[1;97;41m                                                                   bs4it@2022 ${NC}"
echo " "
echo -e "${WHITE}To cancel this operation press CTRL+C${NC}"
confirmationcode=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1`
echo -n -e "${WHITE}Type this confirmation code to completely erase $blkdevice '$confirmationcode':${NC}"
read typedconfirmationcode
if [ $typedconfirmationcode != $confirmationcode ]; then
        echo -e "${YELLOW}Wrong code, quitting${NC}"
        exit 1
fi
echo " "
clear
echo -e "\e[1;97;42m                                                                              ${NC}"
echo -e "\e[1;97;42m                              DISK CONFIGURATION                              ${NC}"
echo -e "\e[1;97;42m                                                                   bs4it@2022 ${NC}"
echo " "
echo -n -e "${WHITE}Wiping data from ${YELLOW}$blkdevice${NC}: "
wipefs -aq /dev/$blkdevice
result=$?
if [ $result != 0 ]; then
	echo -e "Unable to erase device $blkdevice - error $result"
	echo -e "${YELLOW}This device may be mounted or is part of a LVM. Please verify. Quitting.${NC}"
	exit 1
fi
echo -e "${LGREEN}OK${NC}"
echo -n -e "${WHITE}Creating Physical Volume: ${NC}"
pvcreate /dev/$blkdevice 1> /dev/null
result=$?
if [ $result != 0 ]; then
	echo -e "Unable to create Physical Volume - error $result"
	echo -e "This device may be mounted or is part of a LVM. Please verify. Quitting."
	exit 1
fi
echo -e "${LGREEN}OK${NC}"
read -p "Enter the Volume Group Name (vg_backup):" vg_name
	if [ -z $vg_name ]
	then
	        vg_name=$vg_name_default
	fi
echo -n -e "${WHITE}Creating Volume Group $vg_name: ${NC}"
vgcreate $vg_name /dev/$blkdevice 1> /dev/null
result=$?
if [ $result != 0 ]; then
	echo -e "Unable to create Volume Group - error $result"
	echo -e "Fix what is wrong and try again. Quitting."
	exit 1
fi
echo -e "${LGREEN}OK${NC}"
read -p "Enter the Logical Volume Name (lv_backup):" lv_name
	if [ -z $lv_name ]
	then
	        lv_name=$lv_name_default
	fi
echo -n -e "${WHITE}Creating Logical Volume $lv_name using all available space: ${NC}"
lvcreate -l 100%FREE -n $lv_name $vg_name 1> /dev/null
result=$?
if [ $result != 0 ]; then
	echo -e "Unable to create Logical Volume - error $result"
	echo -e "Fix what is wrong and try again. Quitting."
	exit 1
fi
echo -e "${LGREEN}OK${NC}"
echo -n -e "${WHITE}Formating with XFS for fast clone support: ${NC}"
mkfs.xfs /dev/$vg_name/$lv_name 1> /dev/null
result=$?
if [ $result != 0 ]; then
	echo -e "Unable to create XFS filesystem - error $result"
	echo -e "Fix what is wrong and try again. Quitting."
	exit 1
fi
echo -e "${LGREEN}OK${NC}"
echo -n -e "${WHITE}Checking fstab entry for our filesystem: ${NC}"
fstabmount=$(grep "/dev/mapper/$vg_name-$lv_name" /etc/fstab | grep -v '#' | wc -l)
if [ $fstabmount = 0 ]; then
	echo -e ""${YELLOW}Not found. Entry will be created.${NC}""
	echo -n -e "${WHITE}Enter the mountpoint for the new filesystem (e.g. /backup): ${NC}"
	read mountpoint
	if [ -z $mountpoint ]
	then
	    mountpoint=$mountpointdefault
	fi
	echo -n -e "${WHITE}Creating mount point $mountpoint: ${NC}"
	mkdir -p $mountpoint
	echo -e "${LGREEN}OK${NC}"
	sleep 1
        echo -n -e "${WHITE}Writting mount mount to /etc/fstab: ${NC}"
	echo "/dev/mapper/$vg_name-$lv_name $mountpoint xfs    defaults,_netdev        0       0" >> /etc/fstab
	echo -e "${LGREEN}OK${NC}"
else
        echo -e "${LGREEN}Mount point already on fstab.${NC}"
		mountpoint=$(grep /dev/mapper/vg_backup-lv_backup /etc/fstab | grep -v '#' | cut -d " " -f 2)
		mkdir -p $mountpoint
fi
echo -n -e "${WHITE}Mounting all filesystems in /etc/fstab: ${NC}"
mount -a
result=$?
if [ $result != 0 ]; then
	echo ""
    echo -e "Unable to mount some filesystem - error $result"
    echo -e "Verify /etc/fstab"
else
	echo -e "${LGREEN}OK${NC}"
	echo -e "${WHITE}Filesystems mount success.${NC}"
	echo -e "${WHITE}New volume successfully mounted on ${YELLOW}$mountpoint.${NC}"
fi
echo " "
echo -e "${WHITE}Bye!${NC}"
echo " "
