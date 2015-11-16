#! /bin/bash
# -*- coding: utf-8 -*-
# Program: LAMP Stack Installation Script
#Указать переменные 
#MAIL=""
#HOST=""
#echo -n "введите email администратора:"
#read MAIL

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
yum install -y wget sed patch htop atop mytop iftop iotop sysstat


################################################################
# sysstat
yum install -y sysstat
systemctl start sysstat
systemctl enable sysstat
# iostat - выдает статистику использования процессора и потоков ввода/вывода устройств и разделов
# isag - интерактивная программа, строящая график активности системы
# mpstat - сообщает об отдельных параметрах и общей статистики, связанной с процессором
# pidstat - используется для мониторинга отдельных задач, управление которыми выполняется ядром Linux
# sar - собирает, сохраняет и выдает в виде отчетов информацию об активности системы
# sa1 - собирает и сохраняет двоичные данные в файле данных ежедневной активности системы. Это интерфейс sadc, созданный для запуска его из cron
# sa2 - записывает краткий ежедневный отчет об активности системы. Это интерфейс sar, созданный для запуска его из cron
# sadc - является средством сбора данных об активности системы; используется как движок для sar
# sadf - используется для отображения содержимого файлов с данными, созданными с помощью команды sar. Но, в отличие от sar, sadf может записывать свои данные в разнообразных форматах
# http://blog.102web.ru/poleznye-komandy-linux/sysstat-utilita-dlya-izmereniya-proizvoditelnosti/

################################################################
# logwatch
yum install -y logwatch
mkdir /var/cache/logwatch
cp /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/
echo "Format = html" >> /etc/logwatch/conf/logwatch.conf
echo "Service = All" >> /etc/logwatch/conf/logwatch.conf
echo "Service = \"-ftpd-xferlog\"" >> /etc/logwatch/conf/logwatch.conf

cp /usr/share/logwatch/scripts/services/http /etc/logwatch/scripts/services/nginx
cp /usr/share/logwatch/scripts/services/http-error /etc/logwatch/scripts/services/nginx-error
cp /usr/share/logwatch/default.conf/services/http.conf /etc/logwatch/conf/services/nginx.conf
cp /usr/share/logwatch/default.conf/services/http-error.conf /etc/logwatch/conf/services/nginx-error.conf
sed -i 's/Title = "httpd"/Title = "nginx"/g' /etc/logwatch/conf/services/nginx.conf
sed -i 's/LogFile = http/LogFile = nginx/g' /etc/logwatch/conf/services/nginx.conf
sed -i 's/file for http/file for nginx/g' /etc/logwatch/conf/services/nginx.conf
cat << 'EOF' > /etc/logwatch/conf/logfiles/nginx.conf
LogFile = /var/log/nginx/*access.log
Archive = /var/log/nginx/access.log-*.gz

*ExpandRepeats

# keep only the lines in the proper date range
*ApplyhttpDate
EOF

cat << 'EOF' > /etc/logwatch/conf/logfiles/nginx-error.conf
LogFile = /var/log/nginx/*error.log
Archive = /var/log/nginx/error.log-*.gz

# expand the repeats
*ExpandRepeats

# keep only the lines in the proper date range
*ApplyhttpDate
EOF


# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-logwatch-log-analyzer-and-reporter-on-a-vps
# по умолчанию шлет письма через sendmail
# /usr/sbin/logwatch
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

# для управления SELinux
yum -y install policycoreutils-python

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
