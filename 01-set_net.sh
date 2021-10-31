#!/bin/bash
# 2021 - Fernando Della Torre
clear
nic=`lshw -class network | grep "logical name" | cut -d ":" -f 2 | head -1 | xargs`
echo "Definir configuracao de Rede"
echo""
echo "Os valores inseridos serao inseridos nas configuracoes sem validacao."
echo "A configuração sera aplicada a primeira interface encontrada no sistema: $nic"
echo "!!!DIGITE COM CUIDADO!!!"
echo ""
read -p "Hostname (sem sufixo): " newhostname
read -p "Endereco IP para $nic: " ip
read -p "Mascara de rede: " nmask
read -p "Gateway: " gw
read -p "DNS Server 1: " dns1
read -p "DNS Server 2: " dns2
read -p "Sufixo DNS: " dnssuffix
prefix=`ipcalc -n -b $ip $nmask | grep Network: | cut -d ":" -f 2 | cut -d "/" -f 2|xargs`
if [ -z $dns1 ]; then
	dns1="1.1.1.1"
fi
if [ -z $dns2 ]; then
	dns2="8.8.8.8"
fi
if [ -z $dnssuffix ]; then
	dnssuffix="network.intra"
fi
sudo rm -f /etc/netplan/*.yaml
sudo cat > /etc/netplan/01-netcfg.yaml <<EOF
# This is the network config written by 'subiquity'
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

#get current hostname
hostname=`hostname -s`
hostnamectl set-hostname $newhostname
#sed -i "/$hostname/c\127.0.0.1 $newhostname.$dnssuffix $newhostname" /etc/hosts
sed -i "/$hostname/c\127.0.0.1\t$newhostname.$dnssuffix\t$newhostname" /etc/hosts
echo "Aplicando a configuração..."
netplan apply
echo "Feito!"

