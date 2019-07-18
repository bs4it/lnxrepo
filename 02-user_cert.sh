#!/bin/bash



clear
echo " "
echo -e "\e[32mEASY VEEAM LINUX REPOSITORY SCRIPT - BS4IT\e[39m"
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
	echo "Atualizando base do APT"
	apt-get update -y
	clear
	echo "Atualizando S.O."
	apt-get upgrade -y
	clear
	echo "Instalando pacotes"
	apt-get install build-essential -y
	cpan constant Carp Cwd Data::Dumper Encode Encode::Alias Encode::Config Encode::Encoding Encode::MIME::Name Exporter Exporter::Heavy File::Path File::Spec File::Spec::Unix File::Temp List::Util Scalar::Util Socket Storable threads
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

# gera numero aleatorio entre 11000 e 43767
ssh_port=$(($RANDOM+11000))
sed -i "/Port /c\Port $ssh_port" /etc/ssh/sshd_config
echo "Configurando SSH na porta $ssh_port"
sleep 1
/etc/init.d/ssh restart
echo "Configurando Firewall"
ufw --force reset
ufw --force enable
ufw allow $ssh_port/tcp
ufw allow 2500:5000/tcp
sleep 1
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
echo -e "Ao concluir retorne a esta tela e pressione CTRL+C para prosseguir."
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
echo "<p>Realize o download do <a href="https://the.earth.li/~sgtatham/putty/latest/w32/puttygen.exe">PuttyGen</a> para converter a chave privada do formato PEM para o formato PPK, compatível com o Veeam.</p>" >> index.html
echo "<p>" >> index.html
echo "<b>Hostname:</b> `hostname -f`<br>" >> index.html 
echo "<b>Username:</b> $username<br>" >> index.html 
echo "<b>Passphrase:</b> $passphrase<br>" >> index.html
echo "<b>Porta SSH:</b>$ssh_port<br>" >> index.html
echo "</font>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html
echo " "
python3 -m http.server 4080 && rm -f index.html
clear
echo "Limpando arquivos temporarios..."
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


