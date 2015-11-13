#!/bin/bash
# -*- coding: utf-8 -*-
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
#This step concerns only Hetzner servers.
#mv /robot.sh /robot.sh.bak
#rm /etc/rc2.d/S99Zrobot
echo "введите новый пароль для root:"
passwd
echo "PS1='\[\e[0;31m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[0;31m\]\$ \[\e[m\]\[\e[0;32m\]'" >> ~/.bashrc
yum -y install zsh
curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
chsh -s /bin/zshls
cd /tmp
git clone https://github.com/rupa/z.git
cp z/z.sh ~
echo "# include Z, yo" >> ~/.zshrc
echo ". ~/z.sh" >> ~/.zshrc
source ~/.zshrc

if (whiptail --title "Скрипт установки сервера" --yesno "Данный скрипт поможет вам произвести начальную установку сервера и настроить необходимое окружение. Продолжить ?" 10 60) then
    MAIL=$(whiptail --title "email системного администратора" --inputbox "введите имейл для уведомлений системного администратора" 10 60 3>&1 1>&2 2>&3)
    exitstatus=$?
	if [ $exitstatus = 0 ]; then
	HOST=$(whiptail --title "имя host сервера" --inputbox "введите имя хоста сервера" 10 60 3>&1 1>&2 2>&3)
    exitstatus=$?
	if [ $exitstatus = 0 ]; then
	
	whiptail --title "Софт для установки" --checklist --separate-output \
	"Выберите необходимый софт:" 20 78 15 \
	"nginx" "Будет установлен Nginx 1.9  " on \
	"php" "Будет установлен PHP 5.6 FPM Drush Composer  " on \
	"MySQL" "Будет установлен MySQL 5.6  " on \
	"PostgreSQL" "Будет установлен PostgreSQL 9.4  " on \
	"redis" "Будет установлен Redis v 3  " on \
	"Solr" "Будет установлен Apach Solr  " on 2>results
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
	. main.sh
	sleep 5;
	while read choice
	do
	case $choice in
		nginx) . nginx.sh; sleep 5;	;;
		php) . php.sh; sleep 5;	;;
		MySQL) . percona.sh;	;;
		PostgreSQL) . postgresql.sh; sleep 5; ;;
		redis) . redis.sh; sleep 5;	;;
		Solr) . solr.sh; sleep 5; ;;
		*) ;;
	esac
	done < results
	. post_install.sh
	
	else
    echo "You chose Cancel."
	fi
	else
    echo "You chose Cancel."
	fi
	else
    echo "You chose Cancel."
	fi
else
    echo "You chose No. Exit status was $?."
fi