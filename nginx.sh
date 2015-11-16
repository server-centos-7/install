#! /bin/bash
# -*- coding: utf-8 -*-
# Nginx 1.9

systemctl stop httpd
yum erase httpd httpd-tools apr apr-util -y

################################################################
# Install nginx
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
mv /etc/nginx /etc/nginx_default
git clone https://github.com/server-centos-7/nginx.git /etc/nginx

# SSL
yum -y install mod_ssl openssl
mkdir /etc/nginx/ssl

# интересно http://xandroskin.ru/category/it/linux-it/nginx/page/3

$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[Nginx OK]"
$SETCOLOR_NORMAL
echo