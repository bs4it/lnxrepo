#!/bin/bash
echo "Ubuntu 20.04"
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