#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/colors.sh
echo "Debian 11 Detected"
echo -n -e "${WHITE}Updating APT... ${NC}"
update_result=$(apt update -y -qq  2>/dev/null)
echo -e "${YELLOW}$update_result${NC}"
echo -n -e "${WHITE}Upgrading System... ${NC}"
upgrade_result=$(apt dist-upgrade -y -qq  2>/dev/null)
echo -e "${YELLOW}$upgrade_result${NC}"
echo -e "${WHITE}Installing packages... ${NC}"
upgrade_result=$(apt dist-upgrade -y -qq  2>/dev/null)
echo -n -e "${YELLOW}"
apt install -y -qqq wget python3 net-tools vim tcpdump iptraf-ng htop sysstat lvm2 xfsprogs open-iscsi lsscsi nfs-common sudo tmux ufw 2>/dev/null
packages_install_status=$?
if [ $packages_install_status -eq 0 ]; then
  echo -e "${WHITE}Installing packages... ${LGREEN}OK${NC}"
else
  echo -e "${WHITE}Installing packages... ${LRED}FAILED${NC}"
  echo -e "${YELLOW}Check your internet connection and package manager health.${NC}"
  read -p "Press any key to exit."
  exit 1
fi

echo -e "${WHITE}Setting VIM mouse mode${NC}"
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
echo -e "${WHITE}Setting console colors${NC}"
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
echo ""
echo -e "Done!"
sleep 1
exit 0
