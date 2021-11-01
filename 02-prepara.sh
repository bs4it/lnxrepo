#!/bin/bash
clear
echo " "
echo -e "\e[32mVEEAM LINUX REPOSITORY SCRIPT - BS4IT\e[39m"
echo " "
source functions/detect_os.sh
detect_os
echo " "
echo "$os_family"
echo "Atualizar sistema e Instalar pacotes necessarios?"
while [[ -z $installpkgs ]]
do
	echo -ne "Digite \e[97mS\e[39m ou \e[97mN\e[39m:"
	read installpkgs
done
if [ $installpkgs == "S" ] || [ $installpkgs == "s" ]; then
	clear
	source functions/update+install_$os.sh
fi
echo " "
echo "Pressione Enter para continuar:"
read
clear
echo " "
echo -e "\e[32mVEEAM LINUX REPOSITORY SCRIPT - BS4IT\e[39m"
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


echo -e "\e[32m###################################################################"
echo -e "Acesse http://`ifconfig | grep inet | grep -v inet6 | grep -v 127.0.0.1 | sed -e 's/^[[:space:]]*//' | cut -d " " -f 2`:4080,"
echo -e "Para ter acesso as senhas geradas"
echo -e ""
echo -e "Ao concluir retorne a esta tela, digite OK e pressione ENTER."
echo -e "###################################################################\e[39m"
echo '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>Dados de acesso ao repositorio.</title></head>' >index.html
echo "<body>" >> index.html
echo '<font face="Arial, Helvetica, sans-serif">' >> index.html
echo "<h1><font color='#FF0000'>Dados de acesso ao repositorio:</font></h1>" >> index.html
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
python3 -m http.server 4080 &> /dev/null &
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
