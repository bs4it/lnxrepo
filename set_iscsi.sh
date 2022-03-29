#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/functions/colors.sh
source $(dirname "$0")/functions/build_banner.sh
clear
build_banner "iSCSI INITIATOR CONFIGURATION" "bs4it@2022"
echo " "
echo -e "${YELLOW}ATTENTION! Read carefully:${NC}"
echo " "
echo -e "You are about to disconnect all iSCSI sessions and permanently erase all current settings, including your initiator name."
echo -e "${LRED}You may have to re-config your iSCSI target on the storage side in order to connect again.${NC}"
echo " "
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Do you understand and want to proceed with iSCSI setup? (No way back) ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
         echo -e "${WHITE}Removing existing iSCSI sessions and nodes...${NC}"
         echo ""
         echo ""
         iscsiadm -m node --logout
         iscsiadm -m node -o delete
         rm -rf /etc/iscsi/send_targets/*
         sleep 3

         clear
         build_banner "iSCSI INITIATOR CONFIGURATION" "bs4it@2022"
         echo " "
         echo -e "${YELLOW}Setting initiator name:${NC}"
         echo " "
         myhostname=$(hostname -s)
         initiatornamedefault="iqn.2014-04.br.com.bs4it:$myhostname"
         echo -e "${WHITE}Enter new IQN for this initiator or accept the default:${NC}"
         echo -n -e "($initiatornamedefault):"
         read initiatorname
         if [ -z $initiatorname ];then
            initiatorname=$initiatornamedefault
         fi
         echo -e -n "${WHITE}Setting new initiator name...${NC}"
         echo "InitiatorName=$initiatorname" > /etc/iscsi/initiatorname.iscsi
         initiatornamestatus=$?
         sleep 0.3
         if [ $initiatornamestatus -eq 0 ]; then
            echo -e "${LGREEN}OK${NC}"
         else
            echo -e "${LRED}FAILED${NC}"
         fi
         sleep 0.3
         echo -e -n "${WHITE}Setting automatic node startup..."
         sed -i "s/^node.startup = manual.*/# node.startup = manual/" /etc/iscsi/iscsid.conf 2>/dev/null
         sed1status=$?
         sed -i "s/^# node.startup = automatic.*/node.startup = automatic/" /etc/iscsi/iscsid.conf 2>/dev/null
         sed2status=$?
         sleep 0.3
         if [ $sed1status -eq 0 ] && [ $sed2status -eq 0 ]; then
            echo -e "${LGREEN}OK${NC}"
         else
            echo -e "${LRED}FAILED${NC}"
         fi

         sleep 0.3
         if [ $initiatornamestatus -ne 0 ] || [ $sed1status -ne 0 ] || [ $sed2status -ne 0 ]; then
            echo ""
            if [ $initiatornamestatus -ne 0 ]; then
               echo -e "${YELLOW}Something went wrong while setting IQN. Check it manually.${NC}"
            else
               echo -e "${YELLOW}Something went wrong while setting node startup mode. Check it manually.${NC}"
            fi
            read -p "Press any key to exit."
            exit 1
         fi
         sleep 2
         clear
         build_banner "iSCSI INITIATOR CONFIGURATION" "bs4it@2022"
         echo " "
         echo -e "${YELLOW}iSCSI target connection:${NC}"
         echo " "
         discoverystatus="1"
         while [ $discoverystatus -ne 0 ]; do
            echo -e -n "${WHITE}Enter iSCSI target IP: ${NC}"
            read nasip
            echo -e "Discovering targets on ${WHITE}$nasip${NC}..."
            echo ""
            iscsiadm -m discovery -t sendtargets -p $nasip
            discoverystatus=$?
            echo ""
            sleep 0.3
            echo -e -n "${WHITE}Discovery on $nasip "
            sleep 0.3
            if [ $discoverystatus -eq 0 ]; then
               echo -e "${LGREEN}OK${NC}"
            else
               echo -e "${LRED}FAILED${NC}"
               echo -e "Unable to perform discovery."
               tryagain=""
               while ! [[ $tryagain = 'Y' || $tryagain = 'y' || $tryagain = 'N' || $tryagain = 'n' ]]
               do
	               echo -n -e "Do you want to enter NAS IP again? ${YELLOW}(Y/N)${NC}:"
	               read tryagain
	               case $tryagain in
		               y|Y)
                        # loop again
			               ;;
		               n|N)
                        echo "Quitting."
                        exit 1
			               ;;
  	               esac
               done
            fi       
         done
         sleep 2
         
         # Connect to target
         loginstatus="1"
         while [ $loginstatus -ne 0 ] || [ -z "$iscsi_disks" ] ; do
            clear
            build_banner "iSCSI INITIATOR CONFIGURATION" "bs4it@2022"
            echo " "
            echo -e "${YELLOW}iSCSI target connection:${NC}"
            echo " "
            echo -e "\e[1;97;41m!!! ATTENTION !!!${NC}"
            echo -e "${WHITE}Please configure your iSCSI target to accept connections only from the Initiator IQN bellow:"
            echo ""
            echo -e "${YELLOW}$initiatorname${NC}"
            echo ""
            ok="foo"
            until [ $ok = "ok" ]
            do
               echo -n -e "After performing this setting on the target, type OK and hit ENTER: "
               read REPLY
               REPLY=`echo $REPLY | tr '[:lower:]' '[:upper:]'`
               if [[ $REPLY = "OK" ]]; then
                  ok="ok"
               fi
            done
            clear
            build_banner "iSCSI INITIATOR CONFIGURATION" "bs4it@2022"
            echo ""
            echo -e "${YELLOW}iSCSI target connection:${NC}"
            echo ""
            echo -e "${WHITE}Connecting to target..."
            echo ""
            iscsiadm -m node --loginall all
            loginstatus=$?
            echo ""
            sleep 2
            echo ""
            echo -e -n "${WHITE}Connection to target on $nasip "
            sleep 0.3
            if [ $loginstatus -eq 0 ]; then
               echo -e "${LGREEN}OK${NC}"
               # Check if any iSCSI disk is present
               iscsi_disks=""
               sleep 1
               echo ""
               iscsi_disks=$(lsscsi -st | grep disk | grep iqn | rev | cut -d " " -f 6,4,1 -| rev)
               if ! [ -z "$iscsi_disks" ]; then
                  echo -e "${WHITE}The disks below are now connected throught iSCSI:${NC}"
                  echo ""
                  echo -e "${YELLOW}$iscsi_disks${NC}"
                  echo ""
                  sleep 0.6
                  echo "Done!"
               else
                  echo -e "${WHITE}No iSCSI disk is present. Please check the iSCSI target configuration and try again.${NC}"
                  echo ""
                  tryagain=""
                  while ! [[ $tryagain = 'Y' || $tryagain = 'y' || $tryagain = 'N' || $tryagain = 'n' ]]
                  do
                     echo -n -e "Do you want to try again? ${YELLOW}(Y/N)${NC}:"
                     read tryagain
                     case $tryagain in
                        y|Y)
                           # loop again
                           iscsiadm -m node --logout
                           ;;
                        n|N)
                           echo "Quitting."
                           sleep 1
                           exit 1
                           ;;
                     esac
                  done
               fi
            else
               echo -e "${LRED}FAILED${NC}"
               echo -e "Unable to connect to target."
               tryagain=""
               while ! [[ $tryagain = 'Y' || $tryagain = 'y' || $tryagain = 'N' || $tryagain = 'n' ]]
               do
                  echo -n -e "Do you want to try again? ${YELLOW}(Y/N)${NC}:"
                  read tryagain
                  case $tryagain in
                     y|Y)
                        # loop again
                        ;;
                     n|N)
                        echo "Quitting."
                        exit 1
                        ;;
                  esac
               done
            fi       
         done
			;;
		n|N)
         echo "Quitting."
         sleep 1
         exit 1
			;;
  	esac
done
