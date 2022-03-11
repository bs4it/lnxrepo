#!/bin/bash
clear
echo "############################################################################"
echo "CUIDADO AO USAR ESTE SCRIPT, O DISCO INDICADO SERA SUMARIAMENTE FORMATADO!!!"
echo "############################################################################"
echo " "
echo "Para interromper este script pressione ctrl+c."
while [[ $accept != "YES" ]]
do
  read -p "Para prosseguir digite 'YES': " accept
done
clear
echo "############################################################################"
echo "CUIDADO AO USAR ESTE SCRIPT, O DISCO INDICADO SERA SUMARIAMENTE FORMATADO!!!"
echo "############################################################################"
echo " "
echo "Para interromper este script pressione ctrl+c."
echo " "
echo "Os seguintes dispositivos de bloco estao presentes:"
echo " "
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL
#lsblk -f
echo " "
echo "O dispositivo a ser usado NAO deve conter particoes, volumes ou filesystems!"
read -p "Pressione ENTER para seguir"
clear
echo "############################################################################"
echo "CUIDADO AO USAR ESTE SCRIPT, O DISCO INDICADO SERA SUMARIAMENTE FORMATADO!!!"
echo "############################################################################"
echo " "
echo "Para interromper este script pressione ctrl+c."
echo " "
echo "Abaixo a lista de dispositivos SCSI para maiores detalhes:"
lsblk -S
echo " "
while [[ -z "$blkdevice" ]]
do
	read -p "Digite o nome do dispositivo a ser usado (ex. sdb): " blkdevice
done
echo "TODO O CONTEUDO DO DISPOSITIVO $blkdevice SERA PERMANENTEMENTE ELIMINADO"
echo "ESTE PROCESSO NAO PODERA SER REVERTIDO"
echo "O DISCO $blkdevice DEVE ESTAR VAZIO PARA MAIOR SEGURANCA".
echo " "
read -p "Para prosseguir digite novamente o nome do dispositivo: " confirmdevice
if [ $confirmdevice != $blkdevice ]; then
	echo "Confirmacao incorreta, encerrando o script"
	exit 1
fi
clear
echo "############################################################################"
echo "O DISCO $blkdevice SERA APAGADO E RECEBERA A NOVA ESTRUTURA DE LVM"
echo "############################################################################"
echo " "
echo " "
confirmationcode=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1`
read -p "Para realmente continuar digite '$confirmationcode' :" typedconfirmationcode
if [ $typedconfirmationcode != $confirmationcode ]; then
        echo "Codigo incorreto, encerrando o script"
        exit 1
fi
echo " "
echo "Criando volume fisico:"
pvcreate /dev/$blkdevice
result=$?
if [ $result != 0 ]; then
	echo "Falha ao criar volume fisico - erro $result"
	echo "O disco pode conter particoes ou ja participar de um VG. Abortando"
	exit 1
fi
echo " "
echo "Criando volume group:"
vgcreate vg_backup /dev/$blkdevice
result=$?
if [ $result != 0 ]; then
	echo "Falha ao criar volume group - erro $result"
	echo "Corrija erros e execute novamente. Abortando"
	exit 1
fi
echo " "
echo "Criando logical volume usando todo espaco disponivel:"
lvcreate -l 100%FREE -n lv_backup vg_backup
result=$?
if [ $result != 0 ]; then
	echo "Falha ao criar logical volume - erro $result"
	echo "Corrija erros e execute novamente. Abortando"
	exit 1
fi
echo " "
echo "Criando File System com suporte a arquivos grandes:"
mkfs.xfs /dev/vg_backup/lv_backup
result=$?
if [ $result != 0 ]; then
	echo "Falha ao criar sistema de arquivos - erro $result"
	echo "Corrija erros e execute novamente. Abortando"
	exit 1
fi
echo " "
echo "Checando se o fstab já contem o mount point..."
fstabmount=`grep /dev/mapper/vg_veeambackup-lv_veeambackup /etc/fstab`
if [ -z $fstabmount ]; then
	mountpointdefault="/backup"
	echo "Insira o path onde o volume devera ser montado (Ex. /veeambackup): "
	read mountpoint
	if [ -z $mountpoint ]
	then
	        mountpoint=$mountpointdefault
	fi
	echo "Criando a pasta $mountpoint..."
	mkdir -p $mountpoint
	sleep 1
        echo "Inserindo mount mount no arquivo /etc/fstab:"
	echo "/dev/mapper/vg_backup-lv_backup $mountpoint xfs    defaults        0       0" >> /etc/fstab
else
        echo "Mount point ja existente, o arquivo /etc/fstab nao sera alterado."
fi
echo " "
echo "Montando todos os filesystems em /etc/fstab..."
mount -a
result=$?
if [ $result != 0 ]; then
        echo "Falha ao montar filesystems - erro $result"
        echo "Verifique fstab"
else
	echo "Filesystems montados com sucesso."
	echo "novo volume montado com sucesso em `grep /dev/mapper/vg_backup-lv_backup /etc/fstab | cut -d " " -f 2`."
fi
echo " "
echo " "
echo "Processo concluido"
echo " "
