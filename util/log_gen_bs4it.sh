#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
source /opt/veeam/transport/VeeamTransportConfig
user=$ServiceUser
filename="_BS4IT-delete_me_to_get_the_logs"
datetime=$(date +%F_%Hh%Mm%Ss)
users_home=$(getent passwd ${user} | cut -d: -f6)
#echo $users_home
if ! [ -f $users_home/$filename ]; then
   install -m 664 -o $user -g $user /dev/null $users_home/$filename
   install -m 664 -o $user -g $user /dev/null $users_home/_BS4IT-logs_export_in_progress
   rm $users_home/_BS4IT-logs_export_done
   echo "Control file was deleted, deleting old colections and getting logs"
   rm -f $users_home/_VeeamBackup_logs-*.tar.gz
   tar -zcvf $users_home/_VeeamBackup_logs-$datetime.tar.gz $BaseLogDirectory
   chown $user $users_home/_VeeamBackup_logs-*.tar.gz
   rm -f $users_home/_home_veeam_tmp-*.tar.gz
   tar -zcvf $users_home/_home_veeam_tmp-$datetime.tar.gz $users_home/tmp/*
   chown $user $users_home/_home_veeam_tmp-*.tar.gz
   rm -f $users_home/_BS4IT-logs_export_in_progress
   install -m 664 -o $user -g $user /dev/null $users_home/_BS4IT-logs_export_done
else
   echo "Nothing to do"
fi
