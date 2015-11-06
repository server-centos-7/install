#! /bin/bash
# -*- coding: utf-8 -*-
# MySQL Percona 5.6

systemctl stop mysql
yum erase mysql mysql-server -y
rm -rf /var/lib/mysql

################################################################
# Install MySQL:
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

$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[Percona OK]"
$SETCOLOR_NORMAL
echo