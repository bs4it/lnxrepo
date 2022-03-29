#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
# Fills variables with usernames read from local system
localuser=$(grep "Local admin user" /etc/passwd | cut -d ":" -f 1)
adminuser=$(grep "Remote admin user" /etc/passwd | cut -d ":" -f 1)
serviceuser=$(grep "Veeam service user" /etc/passwd | cut -d ":" -f 1)
