#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
sudouser=$1
if [ $os_family == "debian" ]; then
    echo "Removendo do grupo sudo"
	gpasswd --delete $sudouser sudo
elif [ $os_family == "redhat" ]; then
	echo "Removendo do grupo wheel"
	gpasswd --delete $sudouser wheel
else
    echo "Variavel os_family nao definida"
fi