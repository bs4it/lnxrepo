#!/bin/bash
echo "Debian 11"
echo "Atualizando base do APT"
sleep 1
apt-get update -y
clear
echo "Atualizando S.O."
sleep 1
apt-get upgrade -y
clear
echo "Instalando pacotes"
sleep 1
apt-get install wget python3 net-tools vim tcpdump iptraf-ng htop sysstat xfsprogs open-iscsi lsscsi nfs-common sudo tmux ufw -y
echo "Setting VIM mouse mode"
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
echo "Setting console colors"
# Set colors
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
cat << 'EOF' > /etc/profile.d/color.sh
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
