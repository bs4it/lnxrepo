#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/colors.sh
echo "Debian 11 detected"
echo -e "${WHITE}Adding Dell APT repository... ${NC}"
echo 'deb https://linux.dell.com/repo/community/openmanage/10300/focal/ focal main' > /etc/apt/sources.list.d/linux.dell.com.sources.list
echo -e "${WHITE}Installing gnupg2... ${NC}"
apt-get install -y gnupg2
echo -e "${WHITE}Getting repository key... ${NC}"
wget -qO - https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc | apt-key add -
echo -n -e "${WHITE}Updating APT... ${NC}"
apt-get update -y -q
echo -n -e "${WHITE}Installing dependencies ported from Ubuntu 20.04 packages... ${NC}"
upgrade_result=$(apt-get install -y -qq $(dirname "$0")/../dell/deps/*.deb 2>/dev/null)
echo -e "${WHITE}Installing Dell packages... ${NC}"
apt-get install -y -q srvadmin-all
packages_install_status=$?
if [ $packages_install_status -eq 0 ]; then
  echo -e "${WHITE}Installing Dell packages... ${LGREEN}OK${NC}"
  sleep 2
else
  echo -e "${WHITE}Installing Dell packages... ${LRED}FAILED${NC}"
  echo -e "${YELLOW}Check your internet connection and package manager health.${NC}"
  exit 1
fi
echo -e "${WHITE}Starting Dell OMSA Services... ${NC}"
systemctl start dsm_sa_datamgrd.service
systemctl start dsm_sa_eventmgrd.service
systemctl start dsm_sa_snmpd.service
systemctl start dsm_om_connsvc.service
systemctl start dsm_om_shrsvc.service
echo -e "Finished."
exit 0
