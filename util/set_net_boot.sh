#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
clear
echo -e "${YELLOW}Wait..."
sleep 3
clear
bash /root/lnxrepo/set_net.sh
status=$?
if [ $status -eq 2 ]; then
    echo ""
    echo -e "${YELLOW}The network configuration wizard will be presented again on next reboot.${NC}"
    echo "Press ENTER to continue."
    read
else
    systemctl disable set_net.service
fi
exit
