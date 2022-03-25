#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source detect_os.sh
detect_os
# Function to restart ssh service
ssh_restart() {
if [ $os_family == "debian" ]; then
        service ssh restart
elif [ $os_family == "redhat" ]; then
        service sshd restart
fi
}
# Find admin and service usernames
adminuser=`grep "Remote admin user" /etc/passwd | cut -d ":" -f 1`
serviceuser=`grep "Veeam service user" /etc/passwd | cut -d ":" -f 1`
# Lock service user
usermod -s /sbin/nologin $serviceuser
passwd -l $serviceuser
sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/^AllowUsers.*/AllowUsers $adminuser/" /etc/ssh/sshd_config
# Remove service user sudo
source sudo_remove.sh $serviceuser
# Restart SSH
ssh_restart
