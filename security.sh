#! /bin/bash
# -*- coding: utf-8 -*-

#######################################################
# fail2ban
yum -y install fail2ban fail2ban-systemd whois
semanage fcontext -a -t iptables_exec_t '/usr/sbin/ipset'
restorecon -F -v /usr/sbin/ipset
# We need to download the file firewallcmd-ipset.conf and firewallcmd-new.conf 
# from https://github.com/fail2ban/fail2ban/tree/master/config/action.d
# and add them to /etc/fail2ban/action.d
systemctl start fail2ban
systemctl enable fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# проверить ошибки SELinux
# journalctl -lfu fail2ban
# при необходимости 
# grep fail2ban-server /var/log/audit/audit.log | audit2allow -M mypol
# semodule -i mypol.pp
# systemctl restart fail2ban

# мониторить работу journalctl -a -f -n1000 -u fail2ban

#######################################################
# chkrootkit

yum -y install wget
yum install gcc glibc-static
cd /usr/src
wget ftp://ftp.pangeia.com.br/pub/seg/pac/chkrootkit.tar.gz
tar -xzf chkrootkit.tar.gz
cd chkrootkit-0.50
make sense
cd ..
mv chkrootkit-0.50/ /usr/share/
rm -R chkrootkit.tar.gz
#cd /usr/share/chkrootkit-0.50
#./chkrootkit
echo "30 3 * * * /usr/share/chkrootkit-0.50/chkrootkit | mail -s 'CHROOTKIT Daily Run' $MAIL" >> /etc/crontab


#######################################################
# rkhunter

yum -y install rkhunter
rkhunter --update
# Слепок системы
rkhunter --propupd
#rkhunter --check
#rkhunter -c --update --noappend-log --vl
echo "10 3 * * * /usr/bin/rkhunter --update; /usr/bin/rkhunter -c --createlogfile --cronjob --report-warnings-only | mail -s 'RKhunter Scan Details' $MAIL" >> /etc/crontab

#######################################################
# Аудит системы безопасности Lynis
# yum install lynis
cd /usr/share/
git clone https://github.com/CISOfy/Lynis
# cd /usr/share/Lynis
# ./lynis audit system -Q
echo "alias lynis='cd /usr/share/Lynis && ./lynis'" >> ~/.zshrc
# запускать можно так lynis -c -Q
# http://linoxide.com/how-tos/lynis-security-tool-audit-hardening-linux/
# lynis audit system -Q
# grep Warning /var/log/lynis.log
# grep Suggestion /var/log/lynis.log



$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[Security OK]"
$SETCOLOR_NORMAL
echo

