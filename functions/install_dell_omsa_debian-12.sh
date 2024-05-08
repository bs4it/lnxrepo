#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source $(dirname "$0")/colors.sh
echo "Debian 12 detected"
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




Bash:

echo 'deb http://linux.dell.com/repo/community/openmanage/10300/focal focal main' | tee -a /etc/apt/sources.list.d/linux.dell.com.sources.list
wget https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc

apt-key add 0x1285491434D8786F.asc

apt-key export 34D8786F | gpg --dearmour -o /etc/apt/trusted.gpg.d/linux.dell.com.sources.list.gpg

wget -c http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-curl-client-transport1_2.6.5-0ubuntu8_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-client4_2.6.5-0ubuntu8_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman1_2.6.5-0ubuntu8_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-server1_2.6.5-0ubuntu8_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-sfcc/libcimcclient0_2.2.8-0ubuntu2_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/openwsman_2.6.5-0ubuntu8_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/multiverse/c/cim-schema/cim-schema_2.48.0-0ubuntu1_all.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-sfc-common/libsfcutil0_1.0.1-0ubuntu4_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/multiverse/s/sblim-sfcb/sfcb_1.4.9-0ubuntu7_amd64.deb
wget -c http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-cmpi-devel/libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb
wget -c http://ftp.us.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
dpkg -i libwsman-curl-client-transport1_2.6.5-0ubuntu8_amd64.deb
dpkg -i libwsman-client4_2.6.5-0ubuntu8_amd64.deb
dpkg -i libwsman1_2.6.5-0ubuntu8_amd64.deb
dpkg -i libwsman-server1_2.6.5-0ubuntu8_amd64.deb
dpkg -i libcimcclient0_2.2.8-0ubuntu2_amd64.deb
dpkg -i openwsman_2.6.5-0ubuntu8_amd64.deb
dpkg -i cim-schema_2.48.0-0ubuntu1_all.deb
dpkg -i libsfcutil0_1.0.1-0ubuntu4_amd64.deb
dpkg -i sfcb_1.4.9-0ubuntu7_amd64.deb
dpkg -i libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb
dpkg -i libssl1.1_1.1.1w-0+deb11u1_amd64.deb

apt-get update

apt-get install srvadmin-all

# sign out and sign back in

srvadmin-services.sh start


