#!/bin/bash
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
clear
ok="foo"
echo -e "${RED}CUIDADO!"
until [ $ok = "ok" ]
do
  echo ""
  echo -e "${WHITE}Este script desconecta todas as sessões iSCSI e apaga todas as configurações."
  echo -n -e "${WHITE}Para prosseguir digite SIM:"
  read REPLY
  REPLY=`echo $REPLY | tr '[:lower:]' '[:upper:]'`
     if [[ $REPLY = "SIM" ]]
     then
        ok="ok"
     fi
done
echo -e "${WHITE}Removendo sessoes e nodes existentes"
iscsiadm -m node --logout
iscsiadm -m node -o delete
rm -rf /etc/iscsi/send_targets/*
echo ""
sleep 1
echo -e "${WHITE}Ajustando hostname do initiator"
myhostname=`hostname -s`
initiatorname="iqn.2014-04.br.com.bs4it:$myhostname"
echo "InitiatorName=$initiatorname" > /etc/iscsi/initiatorname.iscsi
echo ""
sleep 1
echo -e "${WHITE}Ajustando conexao automatica iSCSI"
sed -i "s/^node.startup = manual.*/# node.startup = manual/" /etc/iscsi/iscsid.conf
sed -i "s/^# node.startup = automatic.*/node.startup = automatic/" /etc/iscsi/iscsid.conf
echo ""
read -p "Insira o IP do iSCSI (NAS):" ip
echo -e "${WHITE}Logando em $ip..."
iscsiadm -m discovery -t sendtargets -p $ip
echo -e "${RED}ATENÇÃO!${NC}"
echo -e "${WHITE}Por favor configure o target para que aceite conexões apenas do Initiator IQN abaixo:"
echo ""
echo -e "${YELLOW}$initiatorname${NC}"
echo ""
ok="foo"
until [ $ok = "ok" ]
do
  echo -n -e "${WHITE}Somente após configurar o target, digite OK para seguir: "
  read REPLY
  REPLY=`echo $REPLY | tr '[:lower:]' '[:upper:]'`
     if [[ $REPLY = "OK" ]]
     then
        ok="ok"
     fi
done
echo -e "${WHITE}Conectando ao target..."
iscsiadm -m node --loginall all
echo ""
echo -e "${WHITE}Os seguintes discos estão conectados:"
sleep 1
lsscsi -s
echo -e "${WHITE}Bye!"





