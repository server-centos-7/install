#! /bin/bash
# -*- coding: utf-8 -*-
# Program: LAMP Stack Installation Script
SHELL=/bin/bash

#Указать переменные 
#echo -n "введите email администратора:"
#read MAIL
#MAIL=""
#HOST=""
cd /tmp

################################################################
# меняем локаль 
LANG=ru_RU.UTF-8
export LANG=ru_RU.UTF-8
LC_MESSAGES=en_US.utf8
export LC_MESSAGES=en_US.utf8
localectl set-locale LANG=ru_RU.UTF-8 LC_MESSAGES=en_US.utf8
################################################################
# устанавливаем хост
hostnamectl set-hostname $HOST
echo "HOSTNAME=$HOST" >> /etc/sysconfig/network

################################################################
# устанавливаем имейл для рута
echo "root: $MAIL" >> /etc/aliases
newaliases
systemctl restart 

################################################################
# Удаление ненужных пакетов
echo "clean_requirements_on_remove=1" >> /etc/yum.conf
systemctl stop smb
yum erase samba samba-client samba-common -y
systemctl stop bind
yum erase bind bind-utils -y
systemctl stop ftp
yum erase ftp -y

################################################################
# Установка обновлений и репозитариев
yum -y update
yum -y upgrade
yum install -y epel-release ius-release yum-priorities 
yum -y update
yum install -y wget sed patch htop atop mytop iftop iotop 


################################################################
# Автоматические обновления
yum -y install yum-cron
sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
echo "YUM_PARAMETER=\"--exclude='kernel*' --exclude='grub*' --exclude='mysql' --exclude='postgresql*' --exclude='nginx*' --exclude='redis*'\"" >> /etc/sysconfig/yum-cron
echo "MAILTO=\"$MAIL\"" >> /etc/sysconfig/yum-cron
systemctl restart yum-cron

################################################################
# Синхронизация времени
timedatectl set-timezone Europe/Moscow
timedatectl set-ntp true
cat << 'EOF' > /etc/systemd/timesyncd.conf
[Time]
NTP=0.ru.pool.ntp.org 2.ru.pool.ntp.org 3.ru.pool.ntp.org time1.google.com time2.google.com time3.google.com time4.google.com pool.ntp.org
EOF
systemctl start systemd-timedated
#yum -y install ntp
#firewall-cmd --add-service=ntp --permanent
#firewall-cmd --reload
#systemctl start ntpd
#systemctl enable ntp
#ntpdate time.apple.com


################################################################
# Install ImageMagick
yum -y install ImageMagick

################################################################
# WEB Stack
#. redis.sh
#. nginx.sh
#. percona.sh
#. php.sh
#. postgresql.sh
#. solr.sh

################################################################
# создание дирректории логов

mkdir -p /data/log

################################################################
# создание дирректории для бекапов
mkdir /backup/pgsql
chown postgres:postgres /backup/pgsql


################################################################
# создание дирректории для бекапов
mkdir /backup/mysql
chown mysql:mysql /backup/mysql
mkdir /backup/pgsql
chown postgres:postgres /backup/pgsql
mkdir /backup/www

#######################################################################################
$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[Base OK]"
$SETCOLOR_NORMAL
echo
