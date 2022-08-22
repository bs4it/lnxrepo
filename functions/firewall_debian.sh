#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
ssh_port=$1
ufw --force reset 1>/dev/null 2>1
ufw default allow outgoing
ufw default deny incoming
ufw allow $ssh_port/tcp
ufw --force enable
