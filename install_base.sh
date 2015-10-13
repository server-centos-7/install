#! /bin/bash
# -*- coding: utf-8 -*-
# Program: LAMP Stack Installation Script

CWD=`pwd`

# меняем локаль
LANG=en_US.utf8
export LANG=en_US.utf8

cd /tmp

# Удаление ненужных пакетов
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

# Установка обновлений и репозитариев
	yum -y update
	yum -y upgrade
	yum install epel-release ius-release
	yum -y update

# админ проги
	yum -y install htop atop pg_top mytop iftop iotop wget



# Автоматические обновления
	yum -y install yum-cron
	# надо добавить в секцию base и update
	echo "exclude=kernel* mysql* postgresql* nginx*" >> /etc/yum.conf
	





# Install and set-up NTP daemon:
    yum install -y ntp
    firewall-cmd --add-service=ntp --permanent
    firewall-cmd --reload
    systemctl start ntpd
    systemctl enable ntp

# Install MySQL:
	yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm \
	Percona-Server-server-56 \
	xtrabackup

	mkdir -p /data/mysql
	touch /data/mysql/mysql.sock
	chown -R mysql:mysql /data/mysql
	chcon -R -t mysqld_db_t /data/mysql
	ln -s /data/mysql/mysql.sock /var/lib/mysql/mysql.sock
	mv /etc/my.cnf /etc/my.cnf.default

	systemctl start mysqld
	systemctl enable mysqld

# Install ImageMagick
	yum -y install ImageMagick

# Install nginx
	[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
/etc/yum.repos.d/nginx.repo
	yum -y update
	yum -y install nginx
    firewall-cmd --permanent --zone=public --add-service=http
	firewall-cmd --permanent --zone=public --add-service=https
	firewall-cmd --reload
	systemctl start nginx
	systemctl enable nginx

# Install PHP-FPM 5.6
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

# Install Redis
	#yum install ius-release
	yum -y install redis30u
	systemctl start redis
    systemctl enable redis


# Install Postgress
	yum localinstall http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-centos94-9.4-1.noarch.rpm
	yum install postgresql94-server

!!! разобраться с натройкой в нестандартную дирректорию по умолчанию /var/lib/pgsql/data/

	postgresql-setup initdb
	systemctl start postgresql
	systemctl enable postgresql

# Install 'composer':

	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
	composer global require drush/drush:7.*

