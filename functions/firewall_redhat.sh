#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
ssh_port=$1
for srv in $(firewall-cmd --list-services);do firewall-cmd --remove-service=$srv; done
for prt in $(firewall-cmd --list-ports);do firewall-cmd --remove-port=$prt; done
firewall-cmd --add-port=$ssh_port/tcp
firewall-cmd --runtime-to-permanent
semanage port -D
semanage port -a -t ssh_port_t -p tcp $ssh_port
