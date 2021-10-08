#!/bin/bash
clear
echo "Removendo sessoes e nodes existentes"
iscsiadm -m node --logout
iscsiadm -m node -o delete
echo "Ajustando hostname do initiator"
myhostname=`hostname -s`
echo "InitiatorName=iqn.1988-12.com.oracle:$myhostname" > /etc/iscsi/initiatorname.iscsi
echo ""
read -p "Insira o IP do iSCSI (NAS):" ip
echo "Logando em $ip..."
iscsiadm -m discovery -t sendtargets -p $ip
iscsiadm -m node --login
echo "Bye!"

