#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/colors.sh
#echo "$os detected"
echo -n -e "${WHITE}Upgrading System, wait... It takes time.${NC}"
dnf update -y 2>/dev/null
dnf upgrade -y 2>/dev/null
echo -e "${WHITE}Installing packages... ${NC}"
# Install EPEL Repository
if [[ $os == "ol-8."* ]]; then
    dnf install oracle-epel-release-el8 -y
else
    dnf install epel-release -y
fi

dnf install wget tar python3 net-tools vim tcpdump iptraf-ng htop sysstat lvm2 xfsprogs lsscsi gdisk nfs-utils sudo bash-completion policycoreutils-python-utils iscsi-initiator-utils -y
packages_install_status=$?
if [ $packages_install_status -eq 0 ]; then
  echo -e "${WHITE}Installing packages... ${LGREEN}OK${NC}"
else
  echo -e "${WHITE}Installing packages... ${LRED}FAILED${NC}"
  echo -e "${YELLOW}Check your internet connection and package manager health.${NC}"
  read -p "Press any key to exit."
  exit 1
fi

echo -e "${WHITE}Building issue file...${NC}"
echo -e "\033[1;34mBS4IT\033[0m - Linux Hardened Repository (\l)" > /etc/issue
echo "Kernel \r on an \m" >> /etc/issue
echo -e "${WHITE}Customising GRUB...${NC}"
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="BS4IT - Linux Hardened Repository"/' /etc/default/grub 2>/dev/null
#sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub 2>/dev/null
if [[ -d /sys/firmware/efi ]]; then
    grubconfigfile=$(readlink -e /etc/grub2-efi.cfg)
else
    grubconfigfile=$(readlink -e /etc/grub2.cfg)
fi
grub2-mkconfig --output $grubconfigfile


# Para Dell OMSA
#yum install net-snmp-utils libcmpiCppImpl0.i686 libcmpiCppImpl0.x86_64 openwsman-server sblim-sfcb sblim-sfcc libwsman1.x86_64 libwsman1.i686 openwsman-client libxslt -y
#wget https://dl.dell.com/FOLDER07414935M/1/OM-SrvAdmin-Dell-Web-LX-10.1.0.0-4561_A00.tar.gz
#tar -zxvf OM-SrvAdmin-Dell-Web-LX-10.1.0.0-4561_A00.tar.gz
#sh setup.sh --express --autostart
alias vi=vim
echo "alias vi=vim" >> /etc/profile

echo -e "${WHITE}Creating log collection script...${NC}"
mkdir -p /opt/bs4it
cat << 'EOF' > /opt/bs4it/veeam_support_log_gen.sh
#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source /opt/veeam/transport/VeeamTransportConfig
user=$ServiceUser
if [ -z $user ]; then
   # if user is empty, exit to avoid breaking the system. it could cause severe damage
   echo "User not found, check VeeamTransportConfig"
   exit 1
fi
filename="_BS4IT-delete_me_to_get_the_logs"
datetime=$(date +%F_%Hh%Mm%Ss)
users_home=$(getent passwd ${user} | cut -d: -f6)
#echo $users_home
if ! [ -f $users_home/$filename ]; then
   install -m 664 -o $user -g $user /dev/null $users_home/$filename
   install -m 664 -o $user -g $user /dev/null $users_home/_BS4IT-logs_export_in_progress
   rm $users_home/_BS4IT-logs_export_done
   echo "Control file was deleted, deleting old colections and getting logs"
   rm -f $users_home/_VeeamBackup_logs-*.tar.gz
   tar -zcvf $users_home/_VeeamBackup_logs-$datetime.tar.gz $BaseLogDirectory
   chown $user $users_home/_VeeamBackup_logs-*.tar.gz
   rm -f $users_home/_home_veeam_tmp-*.tar.gz
   tar -zcvf $users_home/_home_veeam_tmp-$datetime.tar.gz $users_home/tmp/*
   chown $user $users_home/_home_veeam_tmp-*.tar.gz
   rm -f $users_home/_BS4IT-logs_export_in_progress
   install -m 664 -o $user -g $user /dev/null $users_home/_BS4IT-logs_export_done
else
   echo "Nothing to do"
fi
EOF
chmod 700 /opt/bs4it/veeam_support_log_gen.sh
echo -e "${WHITE}Installing crontab job for log collection script...${NC}"
cat << 'EOF' > /etc/cron.d/veeam_support_log_gen
# m h  dom mon dow   command
* * * * * root /opt/bs4it/veeam_support_log_gen.sh
EOF
echo -e "${WHITE}Setting menu autostart...${NC}"
echo "exec sudo /opt/bs4it/lnxrepo/bs4it_setup" > /etc/skel/.bash_profile
if [[ -d /home/localmaint ]]; then
    echo "exec sudo /opt/bs4it/lnxrepo/bs4it_setup" > /home/localmaint/.bash_profile
    chown localmaint:localmaint /home/localmaint/.bash_profile
fi
echo -e "Done!"
sleep 2

exit 0