#! /bin/bash
# -*- coding: utf-8 -*-
echo "exclude=kernel* grub* mysql* postgresql* nginx* redis*" >> /etc/yum.conf
systemctl status mysqld
systemctl status nginx
systemctl status postgresql-9.4.service
systemctl status redis
systemctl status solr
firewall-cmd --state
systemctl status iptables
iptables -L -n
journalctl -lfu fail2ban
echo "Все готово шеф, как вы просили"
echo "поменяй пароль для постгресса"
echo "solr по адресу http://IP:8983 закрыть доступ"
echo "задать пароль для юзера postgresql"