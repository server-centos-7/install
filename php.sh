#! /bin/bash
# -*- coding: utf-8 -*-
# PHP FPM 5.6 Drush Composer

################################################################
# Install PHP-FPM 5.6
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


################################################################
# Install 'composer':
cd ~
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
composer global require drush/drush:7.*

$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[PHP OK]"
$SETCOLOR_NORMAL
echo