#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
# Variaveis
mountpointdefault="/backup"
localuser="localmaint"
adminuserdefault="bs4it"
serviceuserdefault="veeammimi"

source $(dirname "$0")/functions/colors.sh
source $(dirname "$0")/functions/build_banner.sh
source $(dirname "$0")/functions/detect_os.sh
clear
#detect_os
os="debian-11"
# Quit if not running suported O.S.
if ! [[ $os == "debian-11" || $os == "ubuntu-20.04" ]]; then
	echo -e "${LRED}This script does not support your O.S.${NC}"
	echo -e "${LWHITE}You are running ${YELLOW}$os${NC}."
	echo ""
	exit 0
fi
build_banner "ENVIRONMENT CONFIGURATION" "bs4it@2022"
echo " "
echo -e "${YELLOW}General environment settings${NC}"
echo ""
echo -e "${WHITE}The next steps are going to set users, SSH server, firewall, mountpoint and some other details. You may loose SSH connection depending on your settings.${NC}"
echo ""
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Do you really want to go ahead? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			;;
		n|N)
			echo "Quitting, bye!"
			exit 0
			;;
  	esac
done
clear
build_banner "ENVIRONMENT CONFIGURATION" "bs4it@2022"
echo " "
echo -e "${YELLOW}Enter the required information or press ENTER to accept the defaults:${NC}"
echo ""
echo -e -n "${WHITE}Remote administration username ($adminuserdefault): ${NC}"
read adminuser
if [ -z $adminuser ]
then
        adminuser=$adminuserdefault
fi
sleep 0.3

echo -e -n "${WHITE}Service account username ($serviceuserdefault): ${NC}"
read serviceuser
if [ -z $serviceuser ]
then
        serviceuser=$serviceuserdefault
fi
sleep 0.3

ssh_port_rand=$(($RANDOM+11000))
echo -e -n "${WHITE}Custom port for SSH server or accept random ($ssh_port_rand): ${NC}"
read ssh_port
if [ -z $ssh_port ]
then
        ssh_port=$ssh_port_rand
fi
sleep 0.3

echo -e -n "${WHITE}Repository mount point ($mountpointdefault):${NC}"
read mountpoint
if [ -z $mountpoint ]
then
	mountpoint=$mountpointdefault
fi
sleep 0.3


clear
build_banner "ENVIRONMENT CONFIGURATION" "bs4it@2022"
echo " "
echo -e "${YELLOW}The following is about to happen:${NC}"
echo ""
echo -e "${WHITE}Create local administration user ${YELLOW}$localuser${NC}."
sleep 0.2
echo -e "${WHITE}Create remote administration user ${YELLOW}$adminuser${NC}."
sleep 0.2
echo -e "${WHITE}Create service account user ${YELLOW}$serviceuser${NC}."
sleep 0.2
echo -e "${WHITE}Set SSH server to use alternative port ${YELLOW}$ssh_port${NC}."
sleep 0.2
echo -e "${WHITE}Set SSH root login to ${YELLOW}disabled${NC}."
sleep 0.2
echo -e "${WHITE}Set SSH password authentication to ${YELLOW}disabled${NC}."
sleep 0.2
echo -e "${WHITE}Set SSH to allow only one user to login: ${YELLOW}$adminuser${NC}."
sleep 0.2
echo -e "${WHITE}Set Firewall rules accordingly: ${YELLOW}$ssh_port${NC}."
sleep 0.2
echo -e "${WHITE}Set required ownership and permissions on ${YELLOW}$mountpoint${NC}."
sleep 0.2
echo ""
accept=""
while ! [[ $accept = 'Y' || $accept = 'y' || $accept = 'N' || $accept = 'n' ]]
do
	echo -n -e "Is it OK to commit actions? ${YELLOW}(Y/N)${NC}:"
	read accept
	case $accept in
		y|Y)
			echo ""
			;;
		n|N)
			echo "Quitting, bye!"
			exit 0
			;;
  	esac
done

#Creating local user
echo -e -n "Creating local admin user $localuser... "
if id -u "$localuser" >/dev/null 2>&1; then
    echo -e "${YELLOW}User $localuser already exists${NC}"
else
	useradd -s /bin/bash -c "Local admin user" -m localmaint
	localuser_status=$?
	if [ $localuser_status != 0 ]; then
		echo ""
    	echo -e "${LRED}Unable to create user - error $result${NC}"
		echo -e "Quitting."
		sleep 3
		exit 1
	else
		echo -e "${LGREEN}OK${NC}"
	fi
fi
source functions/sudo_add.sh localmaint
localpasswd=`echo SnU1dTZoeGlAJTIwMjEK| base64 -d`
echo "localmaint:$localpasswd" | chpasswd
localpasswd=""

# create remote admin with sudo powers
echo -e -n "Creating remote admin user $adminuser... "
if id -u "$adminuser" >/dev/null 2>&1; then
    echo -e "${YELLOW}User already exists${NC}"
else
	useradd -s /bin/bash -c "Remote admin user" -m $adminuser
	adminuser_status=$?
	if [ $adminuser_status != 0 ]; then
		echo ""
    	echo -e "${LRED}Unable to create user - error $result${NC}"
		echo -e "Quitting."
		sleep 3
		exit 1
	else
		echo -e "${LGREEN}OK${NC}"
	fi
fi
source functions/sudo_add.sh $adminuser
adminpasswd=`openssl rand -base64 32`
echo "$adminuser:$adminpasswd" | chpasswd
su -l $adminuser -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo $adminuserkey >> ~/.ssh/authorized_keys"

# create service account
if id -u "$serviceuser" >/dev/null 2>&1; then
    echo -e "${YELLOW}User already exists${NC}"
else
	useradd -s /sbin/nologin -r -c "Veeam service user" -m $serviceuser
	serviceuser_status=$?
	if [ $serviceuser_status != 0 ]; then
		echo ""
    	echo -e "${LRED}Unable to create user - error $result${NC}"
		echo -e "Quitting."
		sleep 3
		exit 1
	else
		echo -e "${LGREEN}OK${NC}"
	fi
fi
passwd=`openssl rand -base64 32`
echo "$serviceuser:$passwd" | chpasswd
passwd -l $serviceuser


read -p "blablablabla"
# Sets SSH server
sed -i "/Port /c\Port $ssh_port" /etc/ssh/sshd_config
echo "Configurando SSH na porta $ssh_port"
sleep 1
echo "Configurando SSHD"
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


read



adminuserkey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFb+0VowllRHoxIWZdRPPf8tTxd2XueqTOJOn72bxuUv"
# Ajusta SSH e reinicia o servico
sed -i "/Port /c\Port $ssh_port" /etc/ssh/sshd_config
echo "Configurando SSH na porta $ssh_port"
sleep 1
echo "Configurando SSHD"
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

# Configura o firewall local
echo "Configurando Firewall"
source functions/firewall_$os.sh

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

clear
echo " "
echo -e "\e[32mVEEAM LINUX REPOSITORY SCRIPT - BS4IT\e[39m"
echo " "

# criar usuário de servico veeam
if id -u "$username" >/dev/null 2>&1; then
	echo "Usuario $username ja existe."
else
	echo "Criando usuario $username"
	useradd -s /sbin/nologin -r -c "Veeam service user" -m $username
fi
passwd=`openssl rand -base64 32`
echo "$username:$passwd" | chpasswd
passwd -l $username

# criar admin local com direito de root
if id -u "localmaint" >/dev/null 2>&1; then
    echo "Usuario localmaint ja existe."
else
	echo "Criando usuario localmaint"
	useradd -s /bin/bash -c "Local admin user" -m localmaint
fi
source functions/sudo_add.sh localmaint
localpasswd=`echo SnU1dTZoeGlAJTIwMjEK| base64 -d`
echo "localmaint:$localpasswd" | chpasswd
localpasswd=""

# criar admin remoto com direito de root mediante senha
if id -u "$adminuser" >/dev/null 2>&1; then
    echo "Usuario $adminuser ja existe."
else
	echo "Criando usuario $adminuser"
	useradd -s /bin/bash -c "Remote admin user" -m $adminuser
fi
source functions/sudo_add.sh $adminuser
adminpasswd=`openssl rand -base64 32`
echo "$adminuser:$adminpasswd" | chpasswd
su -l $adminuser -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo $adminuserkey >> ~/.ssh/authorized_keys"

echo "Ajustando permissoes para o mount point $mountpoint"
mkdir -p $mountpoint
chown -R $username:$username $mountpoint
chmod -R 700 $mountpoint
sleep 1
fqdn=$(hostname -f)
echo -e "\e[32m###################################################################"
echo -e "Acesse http://`ifconfig | grep inet | grep -v inet6 | grep -v 127.0.0.1 | sed -e 's/^[[:space:]]*//' | cut -d " " -f 2`:4080,"
echo -e "Para ter acesso as senhas geradas"
echo -e ""
echo -e "Ao concluir retorne a esta tela, digite OK e pressione ENTER."
echo -e "###################################################################\e[39m"
cat > index.html <<EOF
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>Dados de acesso ao repositorio.</title></head>'
<body>"
<font face="Arial, Helvetica, sans-serif">'
<h1><font color='#FF0000'>Dados de acesso ao repositorio:</font></h1>"
<h3>Dados para ingresso deste servidor ao console Veeam:</b>.</h3>"
<p>"
<b>Hostname:</b> $fqdn<br>" 
<b>Username:</b> $username<br>" 
<b>Password:</b> $passwd<br>"
<b>Porta SSH:</b>$ssh_port<br>"
<pre>"
</pre>"
</p>"
<h3>Dados para administração remota com chave SSH e passphrase padrão. A senha abaixo deve ser usada para sudo</h3>"
<p>"
<b>Username:</b> $adminuser<br>" 
<b>Password:</b>$adminpasswd<br>"
<b>Porta SSH:</b>$ssh_port<br>"
</font>"
</body>"
</html>"
EOF
echo " "

cat > server.json <<EOF
{
"Name": "$fqdn",
"SSHUser": "$username",
"SSHPassword": "$passwd",
"SSHPort": "$ssh_port",
"Description": "Linux Hardened Repository on $fqdn",
"Path": "$mountpoint"
}
EOF
nohup "bash -c python3 -m http.server 4080 &> /dev/null 2>&1 & wspid=$!;clear; sleep 6; kill -9 $wspid &> /dev/null 2>&1; rm -f index.html server.json" &> /dev/null 2>&1
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
	rm -f server.json
	if [ $os_family == "debian" ]; then
	        ufw delete allow 4080/tcp
	elif [ $os_family == "redhat" ]; then
        	firewall-cmd --remove-port=4080/tcp
	        firewall-cmd --runtime-to-permanent
	fi
	echo "Script finalizado."
	exit
fi
done
