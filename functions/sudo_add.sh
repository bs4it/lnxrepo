#!/bin/bash
sudouser=$1
if [ $os_family == "debian" ]; then
    echo "Adicionando ao grupo sudo"
	usermod -a -G sudo $sudouser
elif [ $os_family == "redhat" ]; then
	echo "Adicionando ao grupo wheel"
	usermod -a -G wheel $sudouser
else
    echo "Variavel os_family nao definida"
fi