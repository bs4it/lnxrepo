#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
echo "OL 8.4"
echo "Atualizando S.O."
sleep 1
yum update -y
clear
echo "Instalando pacotes"
sleep 1
yum install oracle-epel-release-el8 -y
yum install wget tar python3 net-tools vim tcpdump iptraf-ng htop sysstat sudo bash-completion policycoreutils-python-utils iscsi-initiator-utils -y
# Para Dell OMSA
#yum install net-snmp-utils libcmpiCppImpl0.i686 libcmpiCppImpl0.x86_64 openwsman-server sblim-sfcb sblim-sfcc libwsman1.x86_64 libwsman1.i686 openwsman-client libxslt -y
#wget https://dl.dell.com/FOLDER07414935M/1/OM-SrvAdmin-Dell-Web-LX-10.1.0.0-4561_A00.tar.gz
#tar -zxvf OM-SrvAdmin-Dell-Web-LX-10.1.0.0-4561_A00.tar.gz
#sh setup.sh --express --autostart
alias vi=vim
echo "alias vi=vim" >> /etc/profile