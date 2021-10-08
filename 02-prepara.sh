#!/bin/bash
clear
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

clear
echo " "
echo -e "\e[32mEASY VEEAM LINUX REPOSITORY SCRIPT - BS4IT\e[39m"
echo " "
echo " "
echo " "
echo "Atualizar sistema e Instalar pacotes necessarios?"
while [[ -z $installpkgs ]]
do
	echo -ne "Digite \e[97mS\e[39m ou \e[97mN\e[39m:"
	read installpkgs
done
if [ $installpkgs == "S" ] || [ $installpkgs == "s" ]; then
	clear
	if [ $so == "deb" ]; then
		echo "Atualizando base do APT"
		sleep 1
		apt-get update -y
		clear
		echo "Atualizando S.O."
		sleep 1
		apt-get upgrade -y
		clear
		echo "Instalando pacotes"
		sleep 1
		apt-get install wget python3 net-tools vim tcpdump iptraf-ng htop sysstat nfs-common sudo -y
	else
		clear
		echo "Adicionando repositorio EPEL"
		yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
		echo "Atualizando S.O."
		sleep 1
		yum update -y
		clear
		echo "Instalando pacotes"
		sleep 1
		yum install wget tar python3 net-tools vim tcpdump iptraf-ng htop sysstat sudo bash-completion policycoreutils-python-utils iscsi-initiator-utils -y
		# Para Dell OMSA
		yum install net-snmp-utils libcmpiCppImpl0.i686 libcmpiCppImpl0.x86_64 openwsman-server sblim-sfcb sblim-sfcc libwsman1.x86_64 libwsman1.i686 openwsman-client libxslt -y
		wget https://dl.dell.com/FOLDER07414935M/1/OM-SrvAdmin-Dell-Web-LX-10.1.0.0-4561_A00.tar.gz
		tar -zxvf OM-SrvAdmin-Dell-Web-LX-10.1.0.0-4561_A00.tar.gz
        sh setup.sh --express --autostart
		alias vi=vim
		echo "alias vi=vim" >> /etc/profile
	fi
fi
echo " "
echo "Pressione Enter para continuar:"
read
clear
echo " "
echo -e "\e[32mEASY VEEAM LINUX REPOSITORY SCRIPT - BS4IT\e[39m"
echo " "
echo " "
echo " "
echo -n "Insira o nome do usuário de administração remota:"
read adminuser
adminuserkey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFb+0VowllRHoxIWZdRPPf8tTxd2XueqTOJOn72bxuUv"
# gera numero aleatorio entre 11000 e 43767
ssh_port=$(($RANDOM+11000))
# Ajusta SSH e reinicia o servico
sed -i "/Port /c\Port $ssh_port" /etc/ssh/sshd_config
echo "Configurando SSH na porta $ssh_port"
sleep 1

sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "/^PasswordAuthentication.*/d" /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config

egrep ^AllowUsers /etc/ssh/sshd_config >> /dev/null
if [ $? != "0" ]; then
        echo "AllowUsers $adminuser" >> /etc/ssh/sshd_config
else
        sed -i "s/^AllowUsers.*/AllowUsers $adminuser/" /etc/ssh/sshd_config
fi
echo "Configurando SSHD"

# Configura o firewall local
echo "Configurando Firewall"
if [ $so == "deb" ]; then
	ufw default allow outgoing
	ufw default deny incoming
	ufw allow $ssh_port/tcp
	ufw allow 4080/tcp
	ufw --force enable
	service ssh restart
	sleep 1
else
	for srv in $(firewall-cmd --list-services);do firewall-cmd --remove-service=$srv; done
	for prt in $(firewall-cmd --list-ports);do firewall-cmd --remove-port=$prt; done
	firewall-cmd --add-port=4080/tcp
	firewall-cmd --add-port=$ssh_port/tcp
	firewall-cmd --runtime-to-permanent
	semanage port -D
	semanage port -a -t ssh_port_t -p tcp $ssh_port
	service sshd restart
fi

usernamedefault="veeam"
echo -n "Insira o nome do usuario (veeam):"
read username
if [ -z $username ]
then
        username=$usernamedefault
fi

mountpointdefault="/backup"
echo -n "Insira o mountpoint para o repositorio (/backup):"
read mountpoint
if [ -z $mountpoint ]
then
	mountpoint=$mountpointdefault
fi
# criar usuário de servico veeam
echo "Criando usuario $username"
useradd -s /sbin/nologin -r -c "Veeam service user" -m $username
passwd=`openssl rand -base64 32`
echo "$username:$passwd" | chpasswd
passwd -l $username

# criar admin local com direito de root
echo "Criando usuario localmaint"
if [ $so == "deb" ]; then
	usermod -a -G sudo localmaint
else
	useradd -c "Local admin user" -m localmaint
	usermod -a -G wheel localmaint
fi
localpasswd=`echo SnU1dTZoeGlAJTIwMjEK| base64 -d`
echo "localmaint:$localpasswd" | chpasswd
localpasswd=""
# criar admin remoto com direito de root mediante senha
echo "Criando usuario $adminuser"
useradd -s /bin/bash -c "Remote admin user" -m $adminuser
if [ $so == "deb" ]; then
	usermod -a -G sudo $adminuser
else
	usermod -a -G wheel $adminuser
fi
adminpasswd=`openssl rand -base64 32`
echo "$adminuser:$adminpasswd" | chpasswd
su -l $adminuser -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo $adminuserkey >> ~/.ssh/authorized_keys"

echo "Ajustando permissoes para o mount point $mountpoint"
mkdir -p $mountpoint
chown -R $username:$username $mountpoint
chmod -R 700 $mountpoint
sleep 1
clear

echo -e "\e[32m###################################################################"
echo -e "Acesse http://`ifconfig | grep inet | grep -v inet6 | grep -v 127.0.0.1 | sed -e 's/^[[:space:]]*//' | cut -d " " -f 2`:4080,"
echo -e "Para ter acesso as senhas geradas"
echo -e ""
echo -e "Ao concluir retorne a esta tela, digite OK e pressione ENTER."
echo -e "###################################################################\e[39m"
echo '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>Dados de acesso ao repositorio.</title></head>' >index.html
echo "<body>" >> index.html
echo '<font face="Arial, Helvetica, sans-serif">' >> index.html
echo "<h1>Dados de acesso ao repositorio:</h1>" >> index.html
echo "<h3>Dados para ingresso deste servidor ao console Veeam:</b>.</h3>" >> index.html
echo "<p>" >> index.html
echo "<b>Hostname:</b> `hostname -f`<br>" >> index.html 
echo "<b>Username:</b> $username<br>" >> index.html 
echo "<b>Password:</b> $passwd<br>" >> index.html
echo "<b>Porta SSH:</b>$ssh_port<br>" >> index.html
echo "<pre>" >> index.html
echo "</pre>" >> index.html
echo "</p>" >> index.html
echo "<h3>Dados para administração remota com chave SSH e passphrase padrão. A senha abaixo deve ser usada para sudo</h3>" >> index.html
echo "<p>" >> index.html
echo "<b>Username:</b> $adminuser<br>" >> index.html 
echo "<b>Password:</b>$adminpasswd<br>" >> index.html
echo "<b>Porta SSH:</b>$ssh_port<br>" >> index.html
echo "</font>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html
echo " "
python3 -m http.server 4080 &
wspid=$!
while true; do
read -p "Digite OK e tecle ENTER para prosseguir:" ok
if [ -z $ok ]
then
        ok="bad"
fi
if [ $ok == "OK" ] || [ $ok == "ok" ]; then
	clear
	echo "Limpando arquivos temporarios..."
	kill -9 $wspid > /dev/null
	rm -f index.html
	if [ $so == "deb" ]; then
	        ufw delete allow 4080/tcp
	else
        	firewall-cmd --remove-port=4080/tcp
	        firewall-cmd --runtime-to-permanent
	fi
	echo "Script finalizado."
	exit
fi
done
