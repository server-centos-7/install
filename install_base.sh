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
timedatectl set-timezone Europe/Moscow

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
ntpdate time.apple.com

mkdir -p /data/log

##### Install MySQL:
yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm \
Percona-Server-server-56 \
percona-xtrabackup-22

mkdir -p /db/mysql
touch /db/mysql/mysql.sock
chown -R mysql:mysql /db/mysql
chcon -R -t mysqld_db_t /db/mysql
ln -s /db/mysql/mysql.sock /var/lib/mysql/mysql.sock
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
php56u-pgsql \
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
yum -y install postgresql94-server pgtune
## меняем дирректорию
mkdir -p /db/pgsql
chown -R postgres:postgres /db/pgsql/
chcon -t postgresql_db_t /db/pgsql/
semanage fcontext -a -t postgresql_db_t "/db/pgsql(/.*)?"
restorecon -Rv /db/pgsql
su postgres	
/usr/pgsql-9.4/bin/initdb -D /db/pgsql/
exit
su root
cp /usr/lib/systemd/system/postgresql-9.4.service /etc/systemd/system/postgresql-9.4.service
sed -i 's#Environment=PGDATA=/var/lib/pgsql/9.4/data/#Environment=PGDATA=/db/pgsql/#g' /etc/systemd/system/postgresql-9.4.service
pgtune \
    -i /db/pgsql/postgresql.conf \
    -o /db/pgsql/postgresql.conf.pgtune \
    --memory=4294967296 \
    --type=Web \
    --connections=500
sed -i 's#US/Eastern#Europe/Moscow#g' /db/pgsql/postgresql.conf.pgtune
echo "port = 5432" >> /db/pgsql/postgresql.conf.pgtune
echo "ssl = false" >> /db/pgsql/postgresql.conf.pgtune
echo "unix_socket_directory = '/var/run/postgresql'" >> /db/pgsql/postgresql.conf.pgtune
sed -i 's#pg_log#/data/log/postgres/pg_log#g' /db/pgsql/postgresql.conf.pgtune
mv /db/pgsql/postgresql.conf /db/pgsql/postgresql-factory-default.conf
mv /db/pgsql/postgresql.conf.pgtune /db/pgsql/postgresql.conf
chown postgres:postgres /db/pgsql/postgresql.conf
mkdir -p /data/log/postgres
chown postgres:postgres /data/log/postgres
systemctl enable postgresql-9.4.service
systemctl start postgresql-9.4.service

##### админ проги
yum -y install htop atop pg_top mytop iftop iotop patch

##### Install Java 1.8
yum -y install java-1.8.0-openjdk

##### Install Solr 1.5
yum -y yinstall unzip zip lsof 
adduser solr
cd /opt
wget http://apache-mirror.rbc.ru/pub/apache/lucene/solr/5.3.1/solr-5.3.1.tgz
tar -zxvf solr-5.3.1.tgz
firewall-cmd --add-port=8983/tcp --permanent
cp /opt/solr-5.3.1/bin/install_solr_service.sh .
./install_solr_service.sh solr-5.3.1.tgz
rm -rf solr-5.3.1 solr-5.3.1.tgz
cd /tmp
wget http://ftp.drupal.org/files/projects/search_api_solr-7.x-1.x-dev.tar.gz
tar -zxvf search_api_solr-7.x-1.x-dev.tar.gz
cd search_api_solr
wget https://www.drupal.org/files/issues/solr5_conf.patch
patch -p0 < solr5_conf.patch
# русская морфология
wget http://download.services.openoffice.org/files/contrib/dictionaries/ru_RU.zip
unzip ru_RU.zip -d ru_RU
sed -i 's#SET KOI8-R#SET UTF-8#g' ru_RU/ru_RU.aff
iconv -f KOI8-R -t UTF-8 ru_RU/ru_RU.aff > solr-conf/5.x/ru_RU.aff
iconv -f KOI8-R -t UTF-8 ru_RU/ru_RU.dic > solr-conf/5.x/ru_RU.dic
rm -rf ru_RU ru_RU.zip




mkdir -p /var/solr/data/axept/conf
cp -a search_api_solr/solr-conf/5.x/* /var/solr/data/axept/conf
chown -R solr:solr /var/solr/
# меняем дирректорию для индекса
sed -i 's#<dataDir>${solr.data.dir:}</dataDir>#<dataDir>/data/solr/axept/</dataDir>#g' /var/solr/data/axept/conf/solrconfig.xml
mkdir -p /data/solr/axept
chown -R solr:solr /data/solr
/opt/solr/bin/solr create -c axept
systemctl start solr.service
chkconfig --add solr



##### Install 'composer':
cd ~
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
composer global require drush/drush:7.*

echo "Все готово шеф, как вы просили"
echo "поменяй пароль для постгресса"
echo "solr по адресу http://IP:8983 закрыть доступ"
