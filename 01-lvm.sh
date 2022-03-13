#!/bin/bash
# Variaveis
mountpointdefault="/backup"
vg_name_default="vg_backup"
lv_name_default="lv_backup"
source functions/colors.sh
apt install xfsprogs -y
clear
echo -e "\e[1;97;41m                                                                              ${NC}"
echo -e "\e[1;97;41m CUIDADO AO USAR ESTE SCRIPT, O DISCO INDICADO SERA SUMARIAMENTE FORMATADO!!! ${NC}"
echo -e "\e[1;97;41m                                                                              ${NC}"
echo " "
echo -e "${NC}Para interromper este script pressione ctrl+c."
while [[ $accept != "YES" ]]
do
  read -p "Para prosseguir digite 'YES': " accept
done
clear
echo -e "\e[1;97;41m                                                                              ${NC}"
echo -e "\e[1;97;41m CUIDADO AO USAR ESTE SCRIPT, O DISCO INDICADO SERA SUMARIAMENTE FORMATADO!!! ${NC}"
echo -e "\e[1;97;41m                                                                              ${NC}"
echo " "
echo -e "Para interromper este script pressione ctrl+c."
echo " "
echo -e "Os seguintes dispositivos de bloco estao presentes:"
echo " "
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL
#lsblk -f
echo " "
echo -e "O dispositivo a ser usado NAO deve conter particoes, volumes ou filesystems!"
read -p "Pressione ENTER para seguir"
clear
echo -e "\e[1;97;41m                                                                              ${NC}"
echo -e "\e[1;97;41m CUIDADO AO USAR ESTE SCRIPT, O DISCO INDICADO SERA SUMARIAMENTE FORMATADO!!! ${NC}"
echo -e "\e[1;97;41m                                                                              ${NC}"
echo " "
echo -e "Para interromper este script pressione ctrl+c."
echo " "
echo -e "Abaixo a lista de dispositivos SCSI para maiores detalhes:"
lsblk -S
echo " "
while [[ -z "$blkdevice" ]]
do
	read -p "Digite o nome do dispositivo a ser usado (ex. sdb): " blkdevice
done
echo -e "TODO O CONTEUDO DO DISPOSITIVO $blkdevice SERA PERMANENTEMENTE ELIMINADO"
echo -e "ESTE PROCESSO NAO PODERA SER REVERTIDO"
echo -e "O DISCO $blkdevice DEVE ESTAR VAZIO PARA MAIOR SEGURANCA".
echo " "
read -p "Para prosseguir digite novamente o nome do dispositivo: " confirmdevice
if [ $confirmdevice != $blkdevice ]; then
	echo -e "Confirmacao incorreta, encerrando o script"
	exit 1
fi
clear
echo -e "\e[1;97;41m                                                                              ${NC}"
echo -e "\e[1;97;41m         O DISCO $blkdevice SERA APAGADO E RECEBERA A NOVA ESTRUTURA DE LVM          ${NC}"
echo -e "\e[1;97;41m                                                                              ${NC}"
echo " "
echo " "
confirmationcode=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1`
read -p "Para realmente continuar digite '$confirmationcode' :" typedconfirmationcode
if [ $typedconfirmationcode != $confirmationcode ]; then
        echo -e "Codigo incorreto, encerrando o script"
        exit 1
fi
echo " "
echo -e "Criando volume fisico:"
pvcreate /dev/$blkdevice
result=$?
if [ $result != 0 ]; then
	echo -e "Falha ao criar volume fisico - erro $result"
	echo -e "O disco pode conter particoes ou ja participar de um VG. Abortando"
	exit 1
fi
echo " "
echo -e "Criando volume group:"
read -p "Digite o nome desejado para o Volume Group (vg_backup) :" vg_name
	if [ -z $vg_name ]
	then
	        vg_name=$vg_name_default
	fi
vgcreate $vg_name /dev/$blkdevice
result=$?
if [ $result != 0 ]; then
	echo -e "Falha ao criar volume group - erro $result"
	echo -e "Corrija erros e execute novamente. Abortando"
	exit 1
fi
echo " "
read -p "Digite o nome desejado para o Logical Volume (lv_backup) :" lv_name
	if [ -z $lv_name ]
	then
	        lv_name=$lv_name_default
	fi
echo -e "Criando logical volume usando todo espaco disponivel:"
lvcreate -l 100%FREE -n $lv_name $vg_name
result=$?
if [ $result != 0 ]; then
	echo -e "Falha ao criar logical volume - erro $result"
	echo -e "Corrija erros e execute novamente. Abortando"
	exit 1
fi
echo " "
echo -e "Criando File System XFS com suporte a fast clone:"
mkfs.xfs /dev/$vg_name/$lv_name
result=$?
if [ $result != 0 ]; then
	echo -e "Falha ao criar sistema de arquivos - erro $result"
	echo -e "Corrija erros e execute novamente. Abortando"
	exit 1
fi
echo " "
echo -e "Checando se o fstab já contem o mount point..."
fstabmount=`grep /dev/mapper/$vg_name-$lv_name /etc/fstab`
if [ -z $fstabmount ]; then
	echo -e "Insira o path onde o volume devera ser montado (Ex. /backup): "
	read mountpoint
	if [ -z $mountpoint ]
	then
	        mountpoint=$mountpointdefault
	fi
	echo -e "Criando a pasta $mountpoint..."
	mkdir -p $mountpoint
	sleep 1
        echo -e "Inserindo mount mount no arquivo /etc/fstab:"
	echo "/dev/mapper/$vg_name-$lv_name $mountpoint xfs    defaults,_netdev        0       0" >> /etc/fstab
else
        echo -e "Mount point ja existente, o arquivo /etc/fstab nao sera alterado."
fi
echo " "
echo -e "Montando todos os filesystems em /etc/fstab..."
mount -a
result=$?
if [ $result != 0 ]; then
        echo -e "Falha ao montar filesystems - erro $result"
        echo -e "Verifique fstab"
else
	echo -e "Filesystems montados com sucesso."
	echo -e "novo volume montado com sucesso em `grep /dev/mapper/vg_backup-lv_backup /etc/fstab | cut -d " " -f 2`."
fi
echo " "
echo " "
echo -e "Processo concluido"
echo " "
