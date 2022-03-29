#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
sudouser=$1
if [ $os_family == "debian" ]; then
    echo "Removing user $sudouser from group sudo"
	gpasswd --delete $sudouser sudo
elif [ $os_family == "redhat" ]; then
	echo "Removing user $sudouser from group wheel"
	gpasswd --delete $sudouser wheel
else
    echo "The os_family variable is not defined"
fi