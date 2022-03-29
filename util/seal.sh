#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
# prepare the s.o. for the customer
echo "Copying issue file..."
cp $(dirname "$0")/issue /etc/issue
echo "Setting GRUB..."
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="BS4IT - Veeam Linux Hardened Repository"/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub 2>/dev/null
update-grub2
echo "Deleting log.gz files..."
find /var/log/ -type f -name "*.gz" -exec rm -f {} \;
echo "Truncating log files..."
find /var/log/ -type f -exec truncate -s 0 {} \;
echo "Deleting temp files..."
rm -rf /tmp/*
rm -rf /var/tmp/*
echo "Deleting network config files files..."
rm /etc/netplan/*.yaml
rm /etc/network/interfaces
rm /etc/network/interfaces.d/*
echo "Cleaning APT cache..."
apt clean -y
echo "Enabling network configuration wizard on next boot..."
cp $(dirname "$0")/set_net.service /etc/systemd/system/
systemctl enable set_net.service
echo "Cleaning bash history..."
bash -c "cat /dev/null > /root/.bash_history && history -c"
(cat /dev/null > ~/.bash_history; history -c; history -w)
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Do you want to shutdown this machine right now? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo "Shutting down..."
            sleep 1
            shutdown -h 0
			;;
		n|N)
			echo "Quitting, bye!"
			exit 0
			;;
  	esac
done
