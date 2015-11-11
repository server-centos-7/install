#! /bin/bash
# -*- coding: utf-8 -*-

yum -y install ipset
# создание списка blacklist
ipset -N blacklist hash:ip hashsize 4096
ipset -N web_black_list hash:ip timeout 300
# добавление ip  
# ipset add blacklist 192.168.0.5
systemctl stop firewalld
systemctl disable firewalld
yum update && yum -y install iptables-services
systemctl enable iptables
systemctl start iptables

iptables -F
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# ssh
iptables -A INPUT -p tcp -m tcp --dport 8327 -j ACCEPT
# ntp
iptables -I INPUT -p udp --dport 123 -j ACCEPT
# подключение списка blacklist
iptables -A INPUT -m set --match-set blacklist src -j DROP
iptables -A INPUT -m set --match-set web_black_list src -j DROP
iptables -P OUTPUT ACCEPT
iptables -P INPUT DROP

iptables-save | sudo tee /etc/sysconfig/iptables
service iptables restart

$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[iptables OK]"
$SETCOLOR_NORMAL
echo