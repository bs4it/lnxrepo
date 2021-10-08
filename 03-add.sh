#!/bin/bash
adminuser=`grep "Remote admin user" /etc/passwd | cut -d ":" -f 1`
serviceuser=`grep "Veeam service user" /etc/passwd | cut -d ":" -f 1`
if [ -f "/etc/debian_version" ]; then
        so="deb"
        release=`lsb_release -r | cut -d ":" -f 2 | xargs`
        if [ $release != "20.04" ]; then
                echo "Seu Sistema operacional não é suporta"
                echo ""
                echo "Sistemas operacionais suportados:"
                echo "Ubuntu Server 20.04"
                echo "RHEL 8"
                echo "CentOS 8"
                echo "Oracle Enterprise Linux 8"
                exit
        fi
elif [ -f "/etc/redhat-release" ]; then
        so="rhel"
        if [ `rpm -E %{rhel}` != "8" ]; then
                echo "Seu Sistema operacional não é suportado"
                echo " "
                echo "Ubuntu Server 20.04"
                echo "RHEL 8"
                echo "CentOS 8"
                echo "Oracle Enterprise Linux 8"
                exit
        fi
else
        echo "Seu Sistema operacional não é suportado"
        echo " "
        echo "Ubuntu Server 20.04"
        echo "RHEL 8"
        echo "CentOS 8"
        echo "Oracle Enterprise Linux 8"
        exit
fi
usermod -s /bin/bash $serviceuser
passwd -u $serviceuser
sed -i "s/^PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
sed -i "s/^AllowUsers.*/AllowUsers $adminuser $serviceuser/" /etc/ssh/sshd_config

if [ $so == "deb" ]; then
	usermod -a -G sudo $serviceuser
	service ssh restart
else
	usermod -a -G wheel $serviceuser
	service sshd restart
fi
echo "Adicione este server ao Veeam e então tecle ENTER" 
read
usermod -s /sbin/nologin $serviceuser
passwd -l $serviceuser
sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/^AllowUsers.*/AllowUsers $adminuser/" /etc/ssh/sshd_config
if [ $so == "deb" ]; then
	gpasswd --delete $serviceuser sudo
	service ssh restart
else
	gpasswd --delete $serviceuser wheel
	service sshd restart
fi
echo "Feito!"
