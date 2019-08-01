#!/bin/bash

if [ -f "/etc/debian_version" ]; then
	so="deb"
else
	if [ -f "/etc/redhat-release" ]; then
		so="rhel"
		if [ `rpm -E %{rhel}` == "6" ]; then
			rhver="6"
			echo "Versão de RHEL não suportada."
		elif [ `rpm -E %{rhel}` == "7" ]; then
			rhver="7"
		fi
	else
		#SO nao suportado
		echo "Seu Sistema operacional não é suportado"
		echo " "
		echo "Sistemas operacionais suportados:"
		echo "Ubuntu Server 16.04"
		echo "Ubuntu Server 18.04"
		echo "CentOS 7"
		echo "Oracle Enterprise Linux 7"

		exit 
	fi
fi

clear
echo " "
echo -e "\e[32mEASY VEEAM LINUX REPOSITORY SCRIPT - BS4IT\e[39m"
echo " "
echo " "
echo " "



echo " "
echo " "
echo " "
echo "Atualizar sistema e Instalar pacotes necessarios?"
while [[ -z $installpkgs ]]
do
	echo -e "Digite \e[97mS\e[39m ou \e[97mN\e[39m:"
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
		apt-get install net-tools build-essential -y
	cpan constant Carp Cwd Data::Dumper Encode Encode::Alias Encode::Config Encode::Encoding Encode::MIME::Name Exporter Exporter::Heavy File::Path File::Spec File::Spec::Unix File::Temp List::Util Scalar::Util Socket Storable threads
	else
		clear
		echo "Atualizando S.O."
		sleep 1
		yum update -y
		clear
		echo "Instalando pacotes"
		sleep 1
		yum install vim tcpdump net-tools perl perl-Data-Dumper policycoreutils-python -y
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
fi
# gera numero aleatorio entre 11000 e 43767
ssh_port=$(($RANDOM+11000))
service sshd restart

# Configura o firewall local
echo "Configurando Firewall"
if [ $so == "deb" ]; then
	ufw --force reset
	ufw --force enable
	ufw allow $ssh_port/tcp
	ufw allow 2500:5000/tcp
	sleep 1
else
	for srv in $(firewall-cmd --list-services);do firewall-cmd --remove-service=$srv; done
	for prt in $(firewall-cmd --list-ports);do firewall-cmd --remove-port=$prt; done
	firewall-cmd --add-port=$ssh_port/tcp
	firewall-cmd --add-port=2500-5000/tcp
	firewall-cmd --runtime-to-permanent
	semanage port -D
	semanage port -a -t ssh_port_t -p tcp $ssh_port
fi

# Ajusta SSH e reinicia o servico
sed -i "/Port /c\Port $ssh_port" /etc/ssh/sshd_config
echo "Configurando SSH na porta $ssh_port"
sleep 1
service sshd restart


usernamedefault=veeambackup
echo "Insira o nome do usuario (veeambackup):"
read username
if [ -z $username ]
then
        username=$usernamedefault
fi

mountpointdefault="/veeambackup"
echo "Insira o mountpoint para o repositorio (/veeambackup):"
read mountpoint
if [ -z $mountpoint ]
then
	mountpoint=$mountpointdefault
fi

echo "Criando usuario $username"
useradd -s /bin/bash -b /var/lib -c "Veeam Linux user Backup" -m $username
passwd=`openssl rand -base64 32`
echo "$username:$passwd" | chpasswd
passwd -l $username
passphrase=`openssl rand -base64 32`
su -l $username -c "rm -f /var/lib/$username/.ssh/*"
su -l $username -c "ssh-keygen -f /var/lib/$username/.ssh/id_rsa -N $passphrase -C Key_for_Veeam_Linux_user_Backup -O no-x11-forwarding -O no-port-forwarding -O no-agent-forwarding"
su -l $username -c "cat /var/lib/$username/.ssh/id_rsa.pub > /var/lib/$username/.ssh/authorized_keys"
echo "Criando mount point $mountpoint"
mkdir -p $mountpoint
chown $username $mountpoint
chmod 700 $mountpoint
sleep 1
clear
echo -e "\e[32m###################################################################"
echo -e "Acesse http://`ifconfig | grep inet | grep -v inet6 | grep -v 127.0.0.1 | sed -e 's/^[[:space:]]*//' | cut -d " " -f 2`:4080,"
echo -e "Para ter acesso aos dados da chave publica privada"
echo -e ""
echo -e "Ao concluir retorne a esta tela, digite OK e pressione ENTER."
echo -e "###################################################################\e[39m"
echo '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><title>Dados de acesso ao repositorio.</title></head>' >index.html
echo "<body>" >> index.html
echo '<font face="Arial, Helvetica, sans-serif">' >> index.html
echo "<h1>Dados de acesso ao repositorio:</h1>" >> index.html
echo "<h3>Copie a partir da linha abaixo e cole no arquivo <b>private.pem</b>.</h3>" >> index.html
echo "<p>" >> index.html
echo "<pre>" >> index.html
cat /var/lib/$username/.ssh/id_rsa >> index.html
echo "</pre>" >> index.html
echo "</p>" >> index.html
echo "<p>" >> index.html
echo "<h3>Copie ate a linha acima</h3>" >> index.html
echo "</p>" >> index.html
echo '<p>Realize o download do <a href="https://the.earth.li/~sgtatham/putty/latest/w32/puttygen.exe">PuttyGen</a> para converter a chave privada do formato PEM para o formato PPK, compatível com o Veeam.<br>Este ferramenta também pode ser encontrada no Veeam Server em <i>C:\Program Files\Veeam\Backup and Replication\Backup\Putty\</i></p>' >> index.html
echo "<p>" >> index.html
echo "<b>Hostname:</b> `hostname -f`<br>" >> index.html 
echo "<b>Username:</b> $username<br>" >> index.html 
echo "<b>Passphrase:</b> $passphrase<br>" >> index.html
echo "<b>Porta SSH:</b>$ssh_port<br>" >> index.html
echo "</font>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html
echo " "
if [ $so == "deb" ]; then
	python3 -m http.server 4080 &
	wspid=$!
elif [ $rhver == "7" ]; then
	python -m SimpleHTTPServer 4080 &
	wspid=$!
	echo "o pid é $wspid"
fi
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
	echo "Script finalizado."
	echo "Reiniciando em 5 segundos..."
	sleep 1
	echo "Reiniciando em 4 segundos..."
	sleep 1
	echo "Reiniciando em 3 segundos..."
	sleep 1
	echo "Reiniciando em 2 segundos..."
	sleep 1
	echo "Reiniciando em 1 segundos..."
	sleep 1
	echo "Reiniciando..."
	/sbin/shutdown -r now
	exit
fi
done

