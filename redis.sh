#! /bin/bash
# -*- coding: utf-8 -*-
# Redis 3

################################################################
# Install Redis
# yum install ius-release
yum -y install redis30u
sed -i '454 i maxmemory 4GB' /etc/redis.conf

systemctl start redis
systemctl enable redis

$SETCOLOR_SUCCESS
echo -n "$(tput hpa $(tput cols))$(tput cub 15)[Redis OK]"
$SETCOLOR_NORMAL
echo