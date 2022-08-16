#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
# Variables

secondstowait=300
webserver_pid=$1
fqdn=$2
source $(dirname "$0")/functions/colors.sh
source $(dirname "$0")/functions/build_banner.sh
local_ip=$(ip a | grep inet | grep -v inet6 | grep -v 127.0.0.1 | xargs | cut -d " " -f 2 | cut -d "/" -f 1)
#function
convertsecs() {
   ((h=${1}/3600))
   ((m=(${1}%3600)/60))
   ((s=${1}%60))
   #printf "%02d:%02d:%02d\n" $h $m $s
   printf "%02d:%02d\n" $m $s
   }

clear
build_banner "UPGRADE VEEAM COMPONENTS" "bs4it@2022"
echo " "
echo -e "${YELLOW}Upgrading Veeam components.${NC}"
echo ""
echo -e "${WHITE}You MUST use the "'"bs4it_upgrade_repo.ps1"'" PowerShell script to add this repository.${NC}."
echo -e "${WHITE}It can be downloaded now from ${YELLOW}http://$fqdn${NC} or ${YELLOW}http://$local_ip${NC}."
echo ""
if ps -p $webserver_pid > /dev/null
then
   echo "Web server is running."
else
   echo "Web server is not running. Something went wrong."
   echo "Quitting..."
   sleep 3
   exit 1
fi
echo ""
echo -e "You have up to 5 minutes to run the upgrade script on VB&R console."
echo -e "Once you complete it successfully we'll automaticaly proceed."
echo -e "You can also cancel this at any time by pressing "'"CTRL+C"'"."
status="WAIT"
while [[ $secondstowait -gt 0 && $status != "OK" ]]; do
   echo -ne "$(convertsecs $secondstowait)\033[0K\r"
   status=$(cat /tmp/status)
   sleep 1;
   : $((secondstowait--));
done
echo ""
echo "OK"