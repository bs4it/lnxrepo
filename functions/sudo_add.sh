#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
sudouser=$1
if [ $os_family == "debian" ]; then
    echo "Adding user $sudouser to group sudo"
	usermod -a -G sudo $sudouser
elif [ $os_family == "redhat" ]; then
	echo "Adding user $sudouser to group wheel"
	usermod -a -G wheel $sudouser
else
    echo "The os_family variable is not defined"
fi
