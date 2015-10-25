#! /bin/bash
# -*- coding: utf-8 -*-
# Program: LAMP Stack Installation Script
SHELL=/bin/bash

#Указать переменные 
MAIL=""
HOST=""

cd /tmp

##### меняем локаль
LANG=en_US.utf8
export LANG=en_US.utf8

##### устанавливаем хост
hostnamectl set-hostname $HOST
echo "HOSTNAME=$HOST" >> /etc/sysconfig/network

##### устанавливаем имейл для рута
echo "root: $MAIL" >> /etc/aliases
newaliases
systemctl restart 


##### Удаление ненужных пакетов
echo "clean_requirements_on_remove=1" >> /etc/yum.conf
systemctl stop httpd
yum erase httpd httpd-tools apr apr-util -y
systemctl stop smb
yum erase samba samba-client samba-common -y
systemctl stop bind
yum erase bind bind-utils -y
systemctl stop mysql
yum erase mysql mysql-server -y
rm -rf /var/lib/mysql
systemctl stop ftp
yum erase ftp -y

###### Установка обновлений и репозитариев
yum -y update
yum -y upgrade
yum install epel-release ius-release yum-priorities wget sed
yum -y update


##### Автоматические обновления
yum -y install yum-cron
sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
echo "YUM_PARAMETER=\"--exclude='kernel*' --exclude='grub*' --exclude='mysql' --exclude='postgresql*' --exclude='nginx*' --exclude='redis*'\"" >> /etc/sysconfig/yum-cron
echo "MAILTO=\"$MAIL\"" >> /etc/sysconfig/yum-cron
systemctl restart yum-cron

##### Install and set-up NTP daemon:
yum -y install ntp
firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload
systemctl start ntpd
systemctl enable ntp

##### Install MySQL:
yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm \
Percona-Server-server-56 \
percona-xtrabackup-22

mkdir -p /data/mysql
touch /data/mysql/mysql.sock
chown -R mysql:mysql /data/mysql
chcon -R -t mysqld_db_t /data/mysql
ln -s /data/mysql/mysql.sock /var/lib/mysql/mysql.sock
mv /etc/my.cnf /etc/my.cnf.default

systemctl start mysqld
systemctl enable mysqld

##### Install ImageMagick
yum -y install ImageMagick

##### Install nginx
# how to http://stackoverflow.com/questions/2953081/how-can-i-write-a-here-doc-to-a-file-in-bash-script
cat << 'EOF' > /etc/yum.repos.d/nginx.repo
[nginx] 
name=nginx repo
#baseurl=http://nginx.org/packages/centos/7/$basearch/
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
EOF

yum -y update
yum -y install nginx
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
systemctl start nginx
systemctl enable nginx

####### Install PHP-FPM 5.6
yum -y install \
php56u-fpm \
php56u-mysqlnd \
php56u-gd  \
php56u-xml \
php56u-xmlrpc \
php56u-cli \
php56u-mcrypt \
php56u-mbstring \
php56u-pecl-imagick \
php56u-opcache

##### Install Redis
# yum install ius-release
yum -y install redis30u
systemctl start redis
systemctl enable redis


##### Install Postgress
yum -y install http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-2.noarch.rpm
yum -y install postgresql94-server
## меняем дирректорию
mkdir -p /data/pgsql
chown -R postgres:postgres /data/pgsql/
chcon -t postgresql_db_t /data/pgsql/
semanage fcontext -a -t postgresql_db_t "/data/pgsql(/.*)?"
restorecon -Rv /data/pgsql
su postgres	
/usr/pgsql-9.4/bin/initdb -D /data/pgsql/
exit
su root
cp /usr/lib/systemd/system/postgresql-9.4.service /etc/systemd/system/postgresql-9.4.service
sed -i 's#Environment=PGDATA=/var/lib/pgsql/9.4/data/#Environment=PGDATA=/data/pgsql/#g' /etc/systemd/system/postgresql-9.4.service
systemctl enable postgresql-9.4.service
systemctl start postgresql-9.4.service

##### Install Java 1.8
yum -y install java-1.8.0-openjdk

##### Install Solr 1.5
adduser solr
cd /opt
wget http://apache-mirror.rbc.ru/pub/apache/lucene/solr/5.3.1/solr-5.3.1.tgz
tar -zxvf solr-5.3.1.tgz
cp /opt/solr-5.3.1/bin/install_solr_service.sh .
rm -rf solr-5.3.1
./install_solr_service.sh solr-5.3.1.tgz
chkconfig --add solr
chkconfig | grep solr
cd /opt/solr/bin
sudo ./solr create -c axept
sudo chown -R solr:solr /var/solr/

##### админ проги
yum -y install htop atop pg_top mytop iftop iotop 

##### Install 'composer':
cd ~
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
composer global require drush/drush:7.*

echo "Все готово шеф, как вы просили"

