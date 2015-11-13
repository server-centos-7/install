#! /bin/bash
# -*- coding: utf-8 -*-

systemctl start firewalld
firewall-cmd --permanent --remove-service=ssh
# наш порт по ssh
firewall-cmd --permanent --add-port 24563/tcp
# сервисы
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=smtp
firewall-cmd --permanent --add-service=ntp

yum -y install ipset
# создание списка blacklist
ipset -N blacklist hash:ip hashsize 4096
ipset -N web_black_list hash:ip timeout 300
# добавление ip  
# ipset add blacklist 192.168.0.5
# подключение списка
firewall-cmd --direct --add-rule ipv4 filter INPUT 0  -m set --match-set blacklist src -j DROP 
firewall-cmd --direct --add-rule ipv4 filter INPUT 0  -m set --match-set web_black_list src -j DROP 
