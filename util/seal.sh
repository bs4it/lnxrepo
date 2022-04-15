#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
# prepare the s.o. for the customer
echo -e "\033[1;37mBuilding issue file...\033[0m"
echo -e "\033[1;31mBS4IT\033[0m - Veeam Linux Hardened Repository (\l)" > /etc/issue
echo -e "\033[1;37mSetting GRUB...\033[0m"
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="BS4IT - Veeam Linux Hardened Repository"/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub 2>/dev/null
update-grub2
echo -e "\033[1;37mDeleting log.gz files...\033[0m"
find /var/log/ -type f -name "*.gz" -exec rm -f {} \;
echo -e "\033[1;37mTruncating log files...\033[0m"
find /var/log/ -type f -exec truncate -s 0 {} \;
echo -e "\033[1;37mDeleting temp files...\033[0m"
rm -rf /tmp/*
rm -rf /var/tmp/*
echo -e "\033[1;37mDeleting network config files files...\033[0m"
rm /etc/netplan/*.yaml
rm /etc/network/interfaces
rm /etc/network/interfaces.d/*
echo -e "\033[1;37mCleaning APT cache...\033[0m"
apt clean -y
echo -e "\033[1;37mEnabling network configuration wizard on next boot...\033[0m"
cp $(dirname "$0")/set_net.service /etc/systemd/system/
systemctl enable set_net.service
echo -e "\033[1;37mCleaning bash history...\033[0m"
bash -c "cat /dev/null > /root/.bash_history && history -c"
(cat /dev/null > ~/.bash_history; history -c; history -w)
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "\033[1;37mDo you want to shutdown this machine right now? \033[1;33m(Y/N)\033[0m:"
	read accept
	case $accept in
		y|Y)
			echo -e "\033[1;37mShutting down...\033[0m"
            sleep 1
            shutdown -h 0
			;;
		n|N)
			echo -e "\033[1;37mQuitting, bye!\033[0m"
			exit 0
			;;
  	esac
done
