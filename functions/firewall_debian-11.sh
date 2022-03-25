#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
ufw default allow outgoing
ufw default deny incoming
ufw allow $ssh_port/tcp
ufw allow 4080/tcp
ufw --force enable
service ssh restart
