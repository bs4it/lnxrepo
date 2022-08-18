#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/colors.sh
echo "Debian 11 detected"
echo -n -e "${WHITE}Updating APT... ${NC}"
update_result=$(apt-get update -y -qq  2>/dev/null)
echo -e "${YELLOW}$update_result${NC}"
echo -n -e "${WHITE}Upgrading System, wait... ${NC}"
upgrade_result=$(apt-get dist-upgrade -y -qq  2>/dev/null)
echo -e "${YELLOW}$upgrade_result${NC}"
echo -e "${WHITE}Installing packages... ${NC}"
upgrade_result=$(apt-get dist-upgrade -y -qq  2>/dev/null)
echo -n -e "${YELLOW}"
apt-get install -y -qqq wget python3 net-tools vim tcpdump iptraf-ng htop sysstat lvm2 xfsprogs open-iscsi lsscsi scsitools gdisk nfs-common sudo tmux ufw 2>/dev/null
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
echo -e "${WHITE}Customising GRUB...${NC}"
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="BS4IT - Linux Hardened Repository"/' /etc/default/grub 2>/dev/null
#sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub 2>/dev/null
update-grub2
echo -e "${WHITE}Setting VIM mouse mode...${NC}"
# Set vim mouse mode
cat << 'EOF' > /etc/vim/vimrc.local
" This file loads the default vim options at the beginning and prevents
" that they are being loaded again later. All other options that will be set,
" are added, or overwrite the default settings. Add as many options as you
" whish at the end of this file.

" Load the defaults
source $VIMRUNTIME/defaults.vim

" Prevent the defaults from being loaded again later, if the user doesn't
" have a local vimrc (~/.vimrc)
let skip_defaults_vim = 1


" Set more options (overwrites settings from /usr/share/vim/vim80/defaults.vim)
" Add as many options as you whish

" Set the mouse mode to 'r'
if has('mouse')
  set mouse=r
endif
EOF
echo -e "${WHITE}Setting console colors...${NC}"
# Set colors
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
cat << 'EOF' > /etc/profile.d/colors.sh
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF
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
echo "exec sudo /opt/bs4it/lnxrepo/bs4it_setup" > /home/localmaint/.bash_profile
echo -e "Done!"
sleep 2

exit 0
