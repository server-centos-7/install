#! /bin/bash
# -*- coding: utf-8 -*-
PORT=$(whiptail --title "Скрипт настройки ssh и iptables " --inputbox "Введите номер порта, который будет использоваться для подключения по shh и нажмите Ok для продолжения." 10 60 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then

###########################################################
# ipset
yum -y install ipset
# создание списка blacklist
# постоянного
ipset -N blacklist hash:ip hashsize 4096
# оперативного
ipset -N web_black_list hash:ip timeout 300
# добавление ip  
# ipset add blacklist 192.168.0.5

###########################################################
# Настройка SSH

Меняем порт
sed -i 's/#Port 22/Port $PORT/g' /etc/ssh/sshd_config
sed -i 's/#Protocol 2/Protocol 2/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart  sshd
semanage port -a -t ssh_port_t -p tcp #PORTNUMBER

###########################################################
# iptables
systemctl stop firewalld
systemctl disable firewalld
yum update && yum -y install iptables-services
systemctl enable iptables
systemctl start iptables

###########################################################
# IPV4
# сбрасываем правила
iptables -F
# защита от простых атак
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# разрешаем коннект на localhost
iptables -A INPUT -i lo -j ACCEPT
# http
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
# HTTPS
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
# SSH по умолчанию 22, но мы поменяли на $PORT
iptables -A INPUT -p tcp -m tcp --dport $PORT -j ACCEPT
# ntp
iptables -I INPUT -p udp --dport 123 -j ACCEPT
# ping ...
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
# Разрешаем получать уже открытые соединения
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# подключение списка blacklist
iptables -A INPUT -m set --match-set blacklist src -j DROP
iptables -A INPUT -m set --match-set web_black_list src -j DROP
# разрешаем все исходящие соединения
iptables -P OUTPUT ACCEPT
# запрещаем все что не разрешено для входищих
iptables -P INPUT DROP

iptables-save | sudo tee /etc/sysconfig/iptables
service iptables restart

###########################################################
# IPV6
ip6tables -F

ip6tables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
ip6tables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
ip6tables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
ip6tables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# ping ...
ip6tables -A INPUT -p icmp --icmp-type 8 -j ACCEPT

ip6tables -P OUTPUT ACCEPT
ip6tables -P INPUT DROP

ip6tables-save | sudo tee /etc/sysconfig/ip6tables

service ip6tables restart


#######################################################
# psad Система обнаружения вторжений
# http://www.8host.com/blog/ispolzovanie-psad-dlya-opredeleniya-popytok-vzloma-seti-na-ubuntu-vps/
# yum -y install psad


$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[iptables OK]"
$SETCOLOR_NORMAL
echo

else
	echo "You chose Cancel."
fi