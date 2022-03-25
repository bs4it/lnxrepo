#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
# prepare the s.o. for the customer
echo "Copying issue file..."
cp $(dirname "$0")/issue /etc/issue
echo "Setting GRUB..."
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="BS4IT - Veeam Linux Hardened Repository"/' /etc/default/grub 2>/dev/null
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub 2>/dev/null
update-grub2
echo "Enabling network configuration wizard on next boot..."
cp $(dirname "$0")/set_net.service /etc/systemd/system/
systemctl enable set_net.service
echo "Done"
